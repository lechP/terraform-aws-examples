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
}

# Security group allowing SSH access
resource "aws_security_group" "instances_sg" {
  name        = "e003_instances_sg"
  description = "Allow HTTP access and EFS/NFS if needed"
  vpc_id      = data.aws_vpc.default.id

  # ssh access for debugging
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name    = "e003_instances_sg"
    Example = "e003_ec2_efs"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "e003_efs_sg"
  description = "Allow NFS access from instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "NFS from instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instances_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "e003_efs_sg"
    Example = "e003_ec2_efs"
  }
}

resource "aws_efs_file_system" "example_efs" {
  creation_token = "example-efs-token"
  tags = {
    Name    = "example-efs"
    Example = "e003_ec2_efs"
  }
}

resource "aws_efs_mount_target" "example_efs_mt_a" {
  file_system_id  = aws_efs_file_system.example_efs.id
  subnet_id       = local.subnet_a_id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "example_efs_mt_b" {
  file_system_id  = aws_efs_file_system.example_efs.id
  subnet_id       = local.subnet_b_id
  security_groups = [aws_security_group.efs_sg.id]
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
resource "aws_instance" "instance_1_with_efs" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_a_id
  vpc_security_group_ids      = [aws_security_group.instances_sg.id]
  associate_public_ip_address = false

  user_data = templatefile("ec2_userdata.sh.tpl", {
    efs_id     = aws_efs_file_system.example_efs.id
    aws_region = local.region
  })

  depends_on = [
    aws_efs_mount_target.example_efs_mt_a
  ]

  tags = {
    Name    = "ec2_instance_1_with_efs"
    Example = "e003_ec2_efs"
  }
}

# EC2 instance
resource "aws_instance" "instance_2_with_efs" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_b_id
  vpc_security_group_ids      = [aws_security_group.instances_sg.id]
  associate_public_ip_address = false

  user_data = templatefile("ec2_userdata.sh.tpl", {
    efs_id     = aws_efs_file_system.example_efs.id
    aws_region = local.region
  })

  depends_on = [
    aws_efs_mount_target.example_efs_mt_b
  ]

  tags = {
    Name    = "ec2_instance_2_with_efs"
    Example = "e003_ec2_efs"
  }
}
