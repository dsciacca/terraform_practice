provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    encrypt = true
    region = "us-east-1"
  }
}

module "mysql" {
  source = "../../../modules/data-stores/mysql"
  db_name = "example_database_prod"
  db_username = "admin"
  instance_class = "db.t2.micro"
  allocated_storage = 10
  db_password = var.db_password
}
