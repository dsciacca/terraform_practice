provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "elb_port" {
  description = "The port the ELB will use for HTTP requests"
  default = 80
}

variable "cidr_range" {
  description = "The CIDR ranges to allow ingress traffic from"
  default = ["0.0.0.0/0"]
}

variable "http_protocol" {
  description = "HTTP protocol to use: HTTP or HTTPS"
  default = "http"
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "example" {
  image_id = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol  = "tcp"
    cidr_blocks = var.cidr_range
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  ingress {
    from_port = var.elb_port
    protocol = "tcp"
    to_port = var.elb_port
    cidr_blocks = var.cidr_range
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = var.cidr_range
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  load_balancers = [aws_elb.example.name]
  health_check_type = "ELB"

  max_size = 10
  min_size = 2

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform-asg-example"
  }
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups = [aws_security_group.elb.id]

  listener {
    instance_port = var.server_port
    instance_protocol = var.http_protocol
    lb_port = var.elb_port
    lb_protocol = var.http_protocol
  }

  health_check {
    healthy_threshold = 2
    interval = 30
    target = "HTTP:${var.server_port}/"
    timeout = 3
    unhealthy_threshold = 2
  }
}

output "elb_dns_name" {
  value = aws_elb.example.dns_name
}