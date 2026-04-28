terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

variable "ami" {
  description = "ami id (probably ubuntu machine)"
}

variable "instance_type" {
    description = "instance type (t2.micro)"
}

resource "aws_instance" "zenith" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.zenith.key_name
  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive

              # 1. Update and install dependencies
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git fontconfig openjdk-21-jre

              # Install Docker
              install -m0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              
              # Use $$ to escape Terraform interpolation
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              systemctl enable --now docker
              usermod -aG docker ubuntu


              # Install Jenkins
              wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              apt-get update -y
              apt-get install -y jenkins
              sudo usermod -aG docker jenkins
              sudo systemctl restart jenkins
              systemctl enable jenkins

              

              EOF

  tags = { Name = var.instance_name }
}

###### Save private key locally for access
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "zenith_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename = "zenith.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "zenith" {
  key_name   = "zenith"
  public_key = tls_private_key.ssh_key.public_key_openssh
}