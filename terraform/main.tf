terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.0"
    }
  }
}

provider "aws" {
  region  = "sa-east-1"
  profile = "tcc"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "ssh_access" {
  name        = "SSHAccessGroup"
  description = "Security Group allowing SSH access"
}

resource "aws_vpc_security_group_egress_rule" "repositories_access" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "repositories_access_secure" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "github_access" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc" "cluster" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "cluster" {
  vpc_id     = aws_vpc.cluster.id
  cidr_block = "10.0.1.0/24"

}

resource "aws_fsx_lustre_file_system" "example" {
  storage_capacity            = 1200
  subnet_ids                  = [aws_subnet.cluster.id]
  deployment_type             = "PERSISTENT_1"
  per_unit_storage_throughput = 200
}

resource "aws_instance" "cluster" {
  count           = var.cluster_size
  ami             = var.cluster_ami
  instance_type   = "t3.large"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ssh_access.name]
}


resource "aws_s3_bucket" "example" {
  bucket = "test-permissions-tcc-joao"
}

