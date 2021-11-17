data "aws_availability_zones" "all" {}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-40d28157"
  instance_type = var.instance_type
  security_groups = [aws_security_group.instance.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound_instance" {
  type = "ingress"
  from_port = var.server_port
  to_port = var.server_port
  protocol  = "tcp"
  cidr_blocks = var.cidr_range
  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"
}

resource "aws_security_group_rule" "allow_http_inbound_elb" {
  type = "ingress"
  security_group_id = aws_security_group.elb.id
  from_port = var.elb_port
  protocol = "tcp"
  to_port = var.elb_port
  cidr_blocks = var.cidr_range
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = var.cidr_range
  security_group_id = aws_security_group.elb.id
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  load_balancers = [aws_elb.example.name]
  health_check_type = "ELB"

  max_size = var.max_size
  min_size = var.min_size

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.cluster_name}-asg"
  }
}

resource "aws_elb" "example" {
  name = "${var.cluster_name}-asg"
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