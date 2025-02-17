terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
  backend "s3" {
    bucket         = "tcc-terraform-state-cluster"       # Substitua pelo nome do seu bucket S3
    key            = "tcc-state-terraform" # Substitua pelo caminho desejado no bucket S3
    region         = "us-east-1"                  # Região do bucket S3
    dynamodb_table = "tcc-terraform-lock"            # Nome da tabela DynamoDB para lock
    encrypt        = false                         # Habilita a criptografia do estado no S3
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3" {
  source = "./s3module"
  for_each=zipmap(tolist(range(length(local.s3_array))),local.s3_array)
  cluster_instance_type=each.value.instance_type
  cluster_ami=var.cluster_ami
  cluster_size=each.value.cluster_size
  vpc=aws_vpc.cluster.id
  key_name=aws_key_pair.deployer.key_name
  security_group_ids=[aws_security_group.ssh_access.id]
  subnet_id=aws_subnet.cluster.id
  role_name=aws_iam_role.ec2_role.name
  instance_profile=aws_iam_instance_profile.ec2_instance_profile.name
  pure_identifier=each.value.id
}

module "fsx" {
  source = "./fsxmodule"
  for_each=zipmap(tolist(range(length(local.other_modes))),local.other_modes)
  cluster_instance_type=each.value.instance_type
  cluster_size=each.value.cluster_size
  cluster_ami=var.cluster_ami
  vpc=aws_vpc.cluster.id
  key_name=aws_key_pair.deployer.key_name
  security_group_ids=[aws_security_group.ssh_access.id]
  subnet_id=aws_subnet.cluster.id
  pure_identifier=each.value.id
}

resource "aws_vpc" "cluster" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_vpc_security_group_egress_rule" "lustre_access_1" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 988
  ip_protocol       = "tcp"
  to_port           = 988
}

resource "aws_vpc_security_group_ingress_rule" "lustre_access_2" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 988
  ip_protocol       = "tcp"
  to_port           = 988
}

resource "aws_vpc_security_group_egress_rule" "lustre_access_3" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1018
  ip_protocol       = "tcp"
  to_port           = 1023
}

resource "aws_vpc_security_group_ingress_rule" "lustre_access_4" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1018
  ip_protocol       = "tcp"
  to_port           = 1023
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2S3AccessRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "instance_profile_iam"
  role = aws_iam_role.ec2_role.name
}



locals {
         parsed_array = jsondecode(var.config)
	   s3_array     = [for item in local.parsed_array : item if item.mode == "s3"]
	   other_modes  = [for item in local.parsed_array : item if item.mode != "s3"]
	 
}