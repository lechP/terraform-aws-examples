terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lpi-tfstate-3e1989"
    key            = "sandbox/test/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-3"
}

variable "git_commit" {
  description = "Git commit SHA for this deployment"
  type        = string
  default     = "unknown"
}

# Security group allowing HTTP
resource "aws_security_group" "hello_sg" {
  name        = "hello-sg"
  description = "Allow HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
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
    Name = "hello-sg"
  }
}

# Find default VPC & subnet
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
  chosen_subnet_id = data.aws_subnets.default.ids[0]
}

# EC2 instance
resource "aws_instance" "hello" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = local.chosen_subnet_id
  vpc_security_group_ids      = [aws_security_group.hello_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
            #!/bin/bash
            yum install -y httpd
            systemctl enable httpd
            systemctl start httpd

            HOSTNAME=$(hostname)
            TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
            GIT_COMMIT="${var.git_commit}"

            cat <<HTML > /var/www/html/index.html
            <html>
            <head><title>Hello from Terraform</title></head>
            <body>
              <h1>Hello from Terraform!</h1>
              <ul>
                <li><b>Git commit SHA:</b> $${GIT_COMMIT}</li>
                <li><b>Startup timestamp:</b> $${TIMESTAMP}</li>
                <li><b>Hostname:</b> $${HOSTNAME}</li>
              </ul>
            </body>
            </html>
            HTML
            EOF

  tags = {
    Name = "hello-from-terraform"
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

# Output public IP
output "public_ip" {
  value       = aws_instance.hello.public_ip
  description = "Public IP of the hello EC2 instance"
}

output "hello_url" {
  value       = "http://${aws_instance.hello.public_ip}"
  description = "Open this in your browser"
}
