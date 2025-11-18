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

              # --- Wait for EBS device to appear (works for both /dev/xvdf and /dev/nvme1n1) ---
              DEVICE="/dev/xvdf"
              ALT_DEVICE="/dev/nvme1n1"

              echo "Waiting for EBS device to be attached..." >> /var/log/user-data.log
              for i in $(seq 1 30); do
              if [ -b "$DEVICE" ]; then
              FOUND=$DEVICE; break
              elif [ -b "$ALT_DEVICE" ]; then
              FOUND=$ALT_DEVICE; break
              fi
              sleep 3
              done

              if [ -z "$FOUND" ]; then
              echo "EBS device not found after waiting, aborting." >> /var/log/user-data.log
              exit 1
              fi

              # --- Format only if it doesn't already contain a filesystem ---
              if ! blkid "$FOUND"; then
              mkfs -t ext4 "$FOUND"
              fi

              mkdir -p /data
              mount "$FOUND" /data
              echo "$FOUND /data ext4 defaults,nofail 0 2" >> /etc/fstab

              # --- Generate HTML page ---
              GIT_COMMIT="${var.git_commit}"
              # --- Collect filesystem info ---
              MOUNT_INFO=$(df -h | grep /data || echo "Not mounted")


              cat <<HTML > /var/www/html/index.html
              <html>
              <head><title>Hello from Terraform</title></head>
              <body>
                <h1>Hello from Terraform!</h1>
                <ul>
                  <li><b>Git commit SHA:</b> $${GIT_COMMIT}</li>
                </ul>
                <p>Mounted volume:</p>
                <pre>$${MOUNT_INFO}</pre>
              </body>
              </html>
              HTML
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
