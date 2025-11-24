terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  subnet_a_id = data.aws_subnets.default.ids[0]
  subnet_b_id = data.aws_subnets.default.ids[1]
  region      = "eu-west-3"
  example     = "e004_alb"
}

resource "aws_security_group" "alb_sg" {
  name        = "e004_alb_sg"
  description = "Allow HTTP access to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "e004_instances_sg"
    Example = local.example
  }

}

# Security group for EC2 instances - only ALB access
resource "aws_security_group" "instances_sg" {
  name        = "e004_instances_sg"
  description = "Allow HTTP access and EFS/NFS if needed"
  vpc_id      = data.aws_vpc.default.id

  # HTTP access from ALB
  ingress {
    description     = "SSH"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "e004_instances_sg"
    Example = local.example
  }
}

resource "aws_lb" "load_balancer" {
  name               = "e004_alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg]
  subnets            = [local.subnet_a_id, local.subnet_b_id]

  enable_deletion_protection = true

  tags = {
    Name = "e004_alb"
    Example = local.example
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "e004_tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "e004_tg"
    Example = local.example
  }
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}


# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance
resource "aws_instance" "instance_1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_a_id
  vpc_security_group_ids      = [aws_security_group.instances_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            yum install -y httpd
            systemctl enable httpd
            systemctl start httpd

            HOSTNAME=$(hostname)

            cat <<HTML > /var/www/html/index.html
            <html>
            <head><title>Hello from Terraform</title></head>
            <body>
              <ul>
                <li><b>Hostname:</b> $${HOSTNAME}</li>
              </ul>
            </body>
            </html>
            HTML
            EOF

  tags = {
    Name    = "ec2_instance_1"
    Example = local.example
  }
}

# EC2 instance
resource "aws_instance" "instance_2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_b_id
  vpc_security_group_ids      = [aws_security_group.instances_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            yum install -y httpd
            systemctl enable httpd
            systemctl start httpd

            HOSTNAME=$(hostname)

            cat <<HTML > /var/www/html/index.html
            <html>
            <head><title>Hello from Terraform</title></head>
            <body>
              <ul>
                <li><b>Hostname:</b> $${HOSTNAME}</li>
              </ul>
            </body>
            </html>
            HTML
            EOF

  tags = {
    Name    = "ec2_instance_2"
    Example = local.example
  }
}

# Register EC2 instances with target group
resource "aws_lb_target_group_attachment" "tg_attachment_1" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.instance_1.id
}

resource "aws_lb_target_group_attachment" "tg_attachment_2" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.instance_2.id
}
