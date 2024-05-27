terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "ssh_access" {
  name        = "SSHAccessGroup"
  description = "Security Group allowing SSH access"
  vpc_id      = aws_vpc.cluster.id
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

resource "aws_vpc_security_group_egress_rule" "repositories_access_secure_2" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "repositories_access_secure_3" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1
  ip_protocol       = "tcp"
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "repositories_access_secure_4" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1
  ip_protocol       = "udp"
  to_port           = 65535
}

resource "aws_vpc_security_group_ingress_rule" "repositories_access_secure_5" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1
  ip_protocol       = "udp"
  to_port           = 65535
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.cluster.id
  route_table_id = aws_route_table.public_route_table.id
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

resource "aws_vpc" "cluster" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "cluster" {
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_fsx_lustre_file_system" "example" {
  storage_capacity            = 1200
  subnet_ids                  = [aws_subnet.cluster.id]
  deployment_type             = "SCRATCH_1"
  security_group_ids          = [aws_security_group.ssh_access.id]
}

resource "aws_instance" "cluster" {
  count                       = var.cluster_size
  ami                         = var.cluster_ami
  instance_type               = var.cluster_instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.ssh_access.id]
  subnet_id                   = aws_subnet.cluster.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true
    instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 2*data.aws_ec2_spot_price.example.spot_price
    }
  }
}

data "aws_ec2_spot_price" "example" {
  instance_type     = var.cluster_instance_type
  availability_zone = "us-east-1b"
  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}

resource "aws_s3_bucket" "use_on_tests" {
  bucket = "tcc-joao"

}

resource "aws_s3_bucket" "use_to_results" {
  bucket = "results-joao"
}

resource "aws_sqs_queue" "terraform_queue" {
  name                        = "terraform-example-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Política que permite acesso ao bucket S3 específico"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}/*"
        ]
      }
    ]
  })
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

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}