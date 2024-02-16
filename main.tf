#AWS Provider 
provider "aws" {
  region = var.region
}

#Creation of the VPC studi-vpc
resource "aws_vpc" "studi_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "studi-vpc"
  }
}

#Create Internet Gateway studi_igw in the previous VPC
resource "aws_internet_gateway" "studi_igw" {
  vpc_id = aws_vpc.studi_vpc.id
  tags = {
    Name = "studi-igw"
  }
}

#Create Route Table studi_rt in the previous VPC and route allow traffic to internet gw
resource "aws_route_table" "studi_rt" {
  vpc_id = aws_vpc.studi_vpc.id
  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.studi_igw.id
  }
  tags = {
    Name = "studi-rt"
  }
}

#Create 1st subnet named subnet_front in the previous VPC
resource "aws_subnet" "subnet_front" {
  vpc_id     = aws_vpc.studi_vpc.id
  cidr_block = var.subnet_front_cidr_block
  availability_zone = var.az_front
  tags = {
    Name = "subnet_front"
  }
}

#Create 2nd subnet named subnet_back in the previous VPC
resource "aws_subnet" "subnet_back" {
  vpc_id     = aws_vpc.studi_vpc.id
  cidr_block = var.subnet_back_cidr_block
  availability_zone = var.az_back
  tags = {
    Name = "subnet_back"
  }
}

#Associate route table to the subnet_front
resource "aws_route_table_association" "subnet_front_association" {
  subnet_id      = aws_subnet.subnet_front.id
  route_table_id = aws_route_table.studi_rt.id
}

#Associate route table to the subnet_back
resource "aws_route_table_association" "subnet_back_association" {
  subnet_id      = aws_subnet.subnet_back.id
  route_table_id = aws_route_table.studi_rt.id
}

#Create security group sgr_emr_master in the previous VPC 
#Allow SSH ingress and all traffic outbound
resource "aws_security_group" "sgr_emr_master" {
  name        = "sgr_emr_master"
  description = "Security group for EMR Master"
  vpc_id      = aws_vpc.studi_vpc.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = "Allow TCP ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "emr_master"
  }
}

#Create security group sgr_emr_slave in the previous VPC 
#Allow SSH ingress and all traffic egress
resource "aws_security_group" "sgr_emr_slave" {
  name        = "sgr_emr_slave"
  description = "Security group for EMR Slave"
  vpc_id      = aws_vpc.studi_vpc.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = "Allow TCP ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "emr_slave"
  }
}

#Set encryption algorithm for SSH Key pair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Create a Secrete on AWS Manager to store the ssh key
resource "aws_secretsmanager_secret" "private_key_secret" {
  name        = "my_studi_key"
  description = "Key for EMR Cluster"
}

#Set the versionning of the secret and push private ssh key
resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key_secret.id
  secret_string = tls_private_key.rsa.private_key_pem
}

#Create the Public Key that will be push on Ressources and Aws Secret
resource "aws_key_pair" "studi_key" {
  key_name   = "studi_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

#Store also the Private Key in Local as .pem 
resource "local_file" "studi_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "studikey.pem"
}

resource "aws_s3_bucket" "emr_logs" {
  bucket = "my-emr-logs-bucket-${random_id.bucket_suffix.hex}"
  }

resource "aws_s3_bucket_acl" "emr_logs_acl" {
  bucket = aws_s3_bucket.emr_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "emr_logs_versioning" {
  bucket = aws_s3_bucket.emr_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 2
}


#Create Apache Spark Cluster using EC2
resource "aws_emr_cluster" "spark_cluster" {
  name          = var.cluster_name
  release_label = var.release_label 
  applications  = var.applications
  log_uri = "s3://${aws_s3_bucket.emr_logs.bucket}/logs/"

#Create EC2 in the previous subnet_back,with sgr, type of instance and ssh key par
  ec2_attributes {
    subnet_id                         = aws_subnet.subnet_back.id
    instance_profile                  = var.instance_profile
    emr_managed_master_security_group = aws_security_group.sgr_emr_master.id
    emr_managed_slave_security_group  = aws_security_group.sgr_emr_slave.id
    key_name = aws_key_pair.studi_key.key_name
  }

  service_role = var.service_role
  autoscaling_role = var.autoscaling_role

#Set the instance type and bumber of instances for the master instance group
  master_instance_group {
    instance_type  = var.master_instance_type
    instance_count = var.master_instance_count
  }

#Set the instance type and bumber of instances for the core instance group
  core_instance_group {
    instance_type  = var.core_instance_type
    instance_count = var.core_instance_count
  }
}

resource "aws_sns_topic" "emr_alarm_topic" {
  name = "emr-alarm-topic"
}

resource "aws_sns_topic_subscription" "emr_alarm_subscription" {
  topic_arn = aws_sns_topic.emr_alarm_topic.arn
  protocol  = "email"
  endpoint  = "aws.muzzle950@passinbox.com"
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "emr-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElasticMapReduce"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alarm when CPU exceeds 85%"
  alarm_actions       = [aws_sns_topic.emr_alarm_topic.arn]
  dimensions = {
    JobFlowId = aws_emr_cluster.spark_cluster.id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization_high" {
  alarm_name          = "emr-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization" 
  namespace           = "AWS/ElasticMapReduce" 
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alarm when memory exceeds 85%"
  alarm_actions       = [aws_sns_topic.emr_alarm_topic.arn]
  dimensions = {
    JobFlowId = aws_emr_cluster.spark_cluster.id
  }
}

resource "aws_cloudwatch_metric_alarm" "storage_utilization_high" {
  alarm_name          = "emr-storage-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StorageUtilization" 
  namespace           = "AWS/ElasticMapReduce" 
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alarm when storage exceeds 85%"
  alarm_actions       = [aws_sns_topic.emr_alarm_topic.arn]
  dimensions = {
    JobFlowId = aws_emr_cluster.spark_cluster.id
  }
}

#Create the MongoDB Cluster with Document DB
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = var.cluster_identifier
  engine                  = "docdb"
  engine_version          = var.engine_version
  master_username         = var.master_username
  master_password         = var.master_password
  skip_final_snapshot     = true
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
}

#Create Instances in the previous Cluster 
resource "aws_docdb_cluster_instance" "docdb_instances" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.instance_class
  engine             = "docdb"
}

resource "aws_sns_topic" "docdb_alarm_topic" {
  name = "docdb-alarm-topic"
}

resource "aws_sns_topic_subscription" "docdb_alarm_subscription" {
  topic_arn = aws_sns_topic.docdb_alarm_topic.arn
  protocol  = "email"
  endpoint  = "aws.muzzle950@passinbox.com"
}

resource "aws_cloudwatch_metric_alarm" "docdb_cpu_utilization_high" {
  alarm_name          = "docdb-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alarm when CPU exceeds 85%"
  alarm_actions       = [aws_sns_topic.docdb_alarm_topic.arn]
  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.docdb.cluster_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "docdb_memory_utilization_low" {
  alarm_name          = "docdb-memory-utilization-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 15 * 1024 * 1024 * 1024 
  alarm_description   = "Alarm when freeable memory is too low"
  alarm_actions       = [aws_sns_topic.docdb_alarm_topic.arn]
  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.docdb.cluster_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "docdb_storage_utilization_low" {
  alarm_name          = "docdb-storage-utilization-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 10 * 1024 * 1024 * 1024 
  alarm_description   = "Alarm when free storage space is too low"
  alarm_actions       = [aws_sns_topic.docdb_alarm_topic.arn]
  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.docdb.cluster_identifier
  }
}