provider "aws" {
  region = var.region
}

data "aws_ec2_image" "Ubuntu" {
  most_recent = true

  filters = [
    {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-24.10-amd64-server-*"]
    },
    {
      name   = "virtualization-type"
      values = ["hvm"]
    },
  ]
  owners = ["amazon"]
}

data "vpc" "default" {
  default = true
}

module "ssh_security_group" {
  source = "./module/security_group"
  vpc_id = data.vpc.default.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "ec2-key"
  public_key = file("/Users/bentang/.ssh/id_ed25519.pub")
}

resource "aws_ec2_instance" "wesave_deployment" {
  ami                    = data.aws_ec2_image.Ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.vpc.default.default_subnet_id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [module.ssh_security_group.security_group_id]

  tags = {
    Name    = "WeSave"
    Version = "1.0.0"
    host    = "Docker Container"
    Time    = "2025-08-05"
  }

  user_data = file("/Users/bentang/Desktop/terraform-cicd-template/tf/deployment-role/ec2_user_data/user_data")

  provisioner "remote-exec" {
    inline = [user_data]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/Users/bentang/.ssh/id_ed25519")
      host        = self.public_ip
    }
  }
}