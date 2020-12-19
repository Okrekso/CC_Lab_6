provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

variable constants {
  type = object({
    vpc_id = string
    subnets = list(string)
    ami_id = string
  })

  default = {
    vpc_id = "vpc-0c26c15ad6346113d"
    subnets = ["subnet-023091a074f60a83b", "subnet-02b8d57b7c6dc0be3"]
    ami_id = "ami-018c04d38c8fc4bb9"
  }
}

resource "aws_security_group" "this_security_group" {
  name = "for-Lab6"
  vpc_id = var.constants.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "loadbalancer" {
  name = "for-Lab6"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.this_security_group.id]
  subnets = var.constants.subnets
}

resource "aws_instance" "instances" {
    ami = var.constants.ami_id
    instance_type = "t2.micro"
    key_name = "lab3keypair"
    count = 2
    security_groups = [aws_security_group.this_security_group.id]
    associate_public_ip_address = true
    tags = {
      Name = format("lab6-i-%d", count.index)
    }
}

resource "aws_lb_target_group" "tg" {
  name = "for-Lab6"
  target_type = "instance"
  port = 80
  protocol = "HTTP"
  vpc_id = var.constants.vpc_id
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  count = length(aws_instance.instances)
  target_id = aws_instance.instances[count.index].id
  port = 80
}

resource "aws_lb_listener" "http_listiner" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_launch_template" "template" {
  image_id = var.constants.ami_id
  name_prefix = "lab6"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "asg" {
  availability_zones = [ "us-west-2a" ]
  desired_capacity = 2
  max_size = 2
  min_size = 2
  launch_template {
    id = aws_launch_template.template.id
    version = "$Latest"
  }
}