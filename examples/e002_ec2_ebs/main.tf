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
  chosen_subnet_id = data.aws_subnets.default.ids[0]
}

# Security group allowing HTTP access
resource "aws_security_group" "hello_sg" {
  name        = "hello-sg-ebs"
  description = "Allow HTTP access and EFS/NFS if needed"
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
    Name = "hello-sg-ebs"
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

              # Create and mount EBS volume
              if ! file -s /dev/xvdf | grep -q ext4; then
                mkfs -t ext4 /dev/xvdf
              fi
              mkdir /data
              mount /dev/xvdf /data
              echo "/dev/xvdf /data ext4 defaults,nofail 0 2" >> /etc/fstab

              GIT_COMMIT="${var.git_commit}"

              echo "<html><body><h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              echo "<ul><li><b>Git commit SHA:</b> $${GIT_COMMIT}</li></ul>" >> /var/www/html/index.html
              echo "<p>Mounted volume:</p><pre>\$(df -h | grep /data)</pre></body></html>" >> /var/www/html/index.html
              EOF

  tags = {
    Name = "hello-from-terraform-ebs"
  }
}

# Create a separate EBS volume (1 GiB)
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.hello.availability_zone
  size              = 1 # Size in GiB, 1 is minimal for default gp2
  tags = {
    Name = "hello-data-volume"
  }
}

# Attach the volume to the instance
resource "aws_volume_attachment" "data_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.hello.id
}
