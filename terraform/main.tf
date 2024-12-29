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
  spot_price=data.aws_ec2_spot_price.example.spot_price
}

module "fsx" {
  source = "./fsxmodule"
  for_each=zipmap(tolist(range(length(local.other_modes))),local.other_modes)
  cluster_instance_type=each.value.instance_type
  cluster_size=each.value.cluster_size
  cluster_ami=var.cluster_ami
  spot_price=data.aws_ec2_spot_price.example.spot_price
}



data "aws_ec2_spot_price" "example" {
  filter {
    name   = "product-description"
    values = ["Linux"]
  }
}

locals {
         parsed_array = jsondecode(var.config)
	   s3_array     = [for item in local.parsed_array : item if item.mode == "s3"]
	   other_modes  = [for item in local.parsed_array : item if item.mode != "s3"]
	 
}