variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC Studi"
  type = string
  default     = "10.0.0.0/16"
}

variable "subnet_front_cidr_block" {
  description = "The CIDR block for the subnet_front"
  type = string
  default     = "10.0.1.0/24"
}

variable "az_front" {
  description = "AZ For subnet front"
  type = string
  default = "eu-central-1a"  
}

variable "subnet_back_cidr_block" {
  description = "The CIDR block for the subnet_back"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az_back" {
  description = "AZ For subnet back"
  type = string
  default = "eu-central-1b"  
}

variable "master_instance_type" {
  description = "EC2 instance type for the master node"
  type        = string
  default     = "m4.large"
}

variable "master_instance_count" {
  description = "Number of EC2 instances for the master nodes"
  type        = number
  default     = 1
}

variable "core_instance_type" {
  description = "EC2 instance type for the core nodes"
  type        = string
  default     = "m4.large"
}

variable "core_instance_count" {
  description = "Number of EC2 instances for the core nodes"
  type        = number
  default     = 2
}

variable "service_role" {
  description = "The IAM role for the EMR service"
  type        = string
  default     = "EMR_DefaultRole"
}

variable "autoscaling_role" {
  description = "The IAM role for EMR autoscaling"
  type        = string
  default     = "EMR_AutoScaling_DefaultRole"
}

variable "instance_profile" {
  description = "The instance profile for EMR EC2 instances"
  type        = string
  default     = "EMR_EC2_DefaultRole"
}

variable "cluster_name" {
  description = "The name of the EMR cluster"
  type        = string
}

variable "release_label" {
  description = "The release label for the EMR software"
  type        = string
}

variable "applications" {
  description = "List of applications to install on the cluster"
  type        = list(string)
}

variable "cluster_identifier" {
  description = "The identifier for the DocumentDB cluster."
  type        = string
}

variable "engine_version" {
  description = "The engine version for the DocumentDB cluster."
  type        = string
  default     = "5.0.0"
}

variable "master_username" {
  description = "The master username for the DocumentDB cluster."
  type        = string
}

variable "master_password" {
  description = "The master password for the DocumentDB cluster."
  type        = string
}

variable "instance_count" {
  description = "The number of instances in the DocumentDB cluster."
  type        = number
  default     = 3
}

variable "instance_class" {
  description = "The instance class to use for the DocumentDB cluster."
  type        = string
  default     = "db.t3.medium"
}

variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  default     = [22]  
}