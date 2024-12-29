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
      max_price = 2*var.spot_price
    }
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile-${terraform.workspace}"
  role = aws_iam_role.ec2_role.name
}


resource "aws_iam_role" "ec2_role" {
  name = "EC2S3AccessRole-${terraform.workspace}"
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