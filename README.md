**Ajouter du du monitoring par Terraform**  

Je reprends le code principal en rajoutant le code Terraform pour le monitoring https://github.com/p2zbar/ECF-Activite1

**Déployer une infrastructure depuis Terraform , un cluster EMR Spark et un Cluster DocumentDB.**

Liens utiles :  
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code  
https://aws.amazon.com/emr/features/spark/  
https://aws.amazon.com/nosql/document/

Prérequis:
- Créer un compte AWS (ne pas utiliser le compte racine)  
https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html

- Créer un utilisateur IAM avec les droits admins, enregistrer les credentials qui seront utilisés dans l'étape suivante  
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html

- Installer et configurer AWS cli avec votre Access Key et Secret sur larégionn de votre choix (dans mon cas eu-central-1)  
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

- Installer Terraform cli  
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

- Un IDE de votre choix dans ma situation VSCode avec les extensions Terraform.

Cloner le repo
```
git clone git@github.com:p2zbar/ECF-Activite1.git
```
 
Le code est divisée en 3fichiers ::  
  
**main.tf** contient tout le code de lacréationn d'un VPC , une IGW , uneroutee table , 2 Security-groups, 2 subnets , 1 cluster EMR (1 core , 1 master) et 1 cluster Document DB (3 instances en db.t3.medium).  
**variables.tf** permet de ne pasécriree tout le code en dur et facilite la réutilisation du projet pour une autre infra.  
**terraform.tvars** contient les valeurs qui serontutiliséess dans le variables.tf si pas de variable default de configurer.

Pour lancer le projet:
- Ouvrir un terminal dans votre IDE  
Initierr le projet  
```
terraform init 
```
creer un plan d'execution, permet de visualiser les differentes actions que Terraform prevoit d'apporter
```
terraform plan
```
applique le terraform plan
```
terraform apply
```

Confirmer le deploiement en tapant Yes  
Une fois que l'apply est termine un message "Apply compete! Resources: x Added,0 changed, 0 destroyed"  

Si vous vous rendez sur AWS Console > EMR 
Le cluster EMR aura été crée.

Si vous vous rendez sur AWS Console > DocumentDB
Le cluster DocumentDB aura été crée.

Pour supprimer tout ce qui a été crée.
```
terraform destroy
```
Confirmer en tapant yes

Un message vous seraaffichée "Destroy Completed"
