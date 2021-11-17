provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    encrypt = true
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "image-type"
    values = ["machine"]
  }
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  ami = data.aws_ami.ubuntu.id
  server_text = "Hello, World"
  aws_region = var.aws_region
  cluster_name = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key = var.db_remote_state_key

  instance_type = "t2.micro"
  max_size = 10
  min_size = 2
  enable_autoscaling = 0
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  from_port = 12345
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.webserver_cluster.elb_security_group_id
  to_port = 12345
  type = "ingress"
}