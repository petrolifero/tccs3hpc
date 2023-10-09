terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.20.0"
    }
  }
}

provider "aws" {
    region = "sa-east-1"
    profile = "tcc"
}




resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

}

resource "aws_fsx_lustre_file_system" "example" {
  storage_capacity            = 1200
  subnet_ids                  = [aws_subnet.main.id]
  deployment_type             = "PERSISTENT_1"
  per_unit_storage_throughput = 200
}

resource "aws_instance" "cluster" {
  count         = 10
  ami           = "ami-0393d979714af82dd"
  instance_type = "t3.micro"
}


resource "aws_s3_bucket" "example" {
  bucket = "test-permissions-tcc-joao"
}

output "public_ip_addresses" {
  description = "Endereços IP públicos das instâncias EC2"
  value       = aws_instance.cluster[*].public_ip
}