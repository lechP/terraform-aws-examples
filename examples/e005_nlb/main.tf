terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  example = "e005_nlb"
}


# ------------------------------------------------------------------------------------
# VPC + Subnets
# ------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.6.0"

  name = "e005-nlb-vpc"
  cidr = "10.100.0.0/16"

  azs             = [for az in var.azs : az]
  public_subnets  = [for i in range(length(var.azs)) : cidrsubnet("10.100.0.0/16", 4, i)]
  private_subnets = [for i in range(length(var.azs)) : cidrsubnet("10.100.0.0/16", 4, i + 4)]

  enable_nat_gateway = true

  tags = {
    Name    = "e005_nlb_vpc"
    Example = local.example
  }
}

# ------------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------------

resource "aws_security_group" "instance_sg" {
  name   = "e005_instances_sg"
  vpc_id = module.vpc.vpc_id

  # Only allow traffic from NLB subnets
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "e005_instances_sg"
    Example = local.example
  }
}

# ------------------------------------------------------------------------------------
# EC2 Instances (3x, private subnets)
# ------------------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  count                       = 3
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = false

  user_data = templatefile("ec2_userdata.sh.tpl", {})

  tags = {
    Name    = "${local.example}_ec2_instance_${count.index}"
    Example = local.example
  }
}

# ------------------------------------------------------------------------------------
# Network Load Balancer (public)
# ------------------------------------------------------------------------------------

resource "aws_lb" "nlb" {
  name               = "e005nlb"
  load_balancer_type = "network"
  internal           = false

  subnets = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true

  tags = {
    Name    = "e005_nlb"
    Example = local.example
  }
}

# ------------------------------------------------------------------------------------
# Target Groups
# ------------------------------------------------------------------------------------

resource "aws_lb_target_group" "tg_main" {
  name        = "e005-nlb-tg-main"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = {
    Name    = "e005_nlb_tg_main"
    Example = local.example
  }
}

resource "aws_lb_target_group" "tg_canary" {
  name        = "e005-nlb-tg-canary"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = {
    Name    = "e005_nlb_tg_canary"
    Example = local.example
  }
}

resource "aws_lb_target_group_attachment" "attachment_main" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg_main.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attachment_canary" {
  target_group_arn = aws_lb_target_group.tg_canary.arn
  target_id        = aws_instance.app[2].id # Attach the 3rd instance as canary
  port             = 80
}

# ------------------------------------------------------------------------------------
# Listener
# ------------------------------------------------------------------------------------

resource "aws_lb_listener" "tcp80" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg_main.arn
        weight = 90
      }
      target_group {
        arn    = aws_lb_target_group.tg_canary.arn
        weight = 10
      }
    }
  }
}
