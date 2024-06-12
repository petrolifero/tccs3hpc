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
  count = var.isFSX ? 1 : 0
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
  count = var.isS3? 1 : 0

}

resource "aws_s3_bucket" "use_to_results" {
  bucket = "results-joao-${terraform.workspace}"
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy-${terraform.workspace}"
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
        "Resource": concat(var.isS3? [
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests[0].bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests[0].bucket}/*"]: [],
	  ["arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}/*"])
      }
    ]
  })
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

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile-${terraform.workspace}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_lambda_function" "terraform_lambda" {
  filename         = "./lambda_function.zip"
  function_name    = "TerraformWorkspaceDestroyer-${terraform.workspace}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = filebase64sha256("./lambda_function.zip")
  runtime          = "python3.12"
  layers = [aws_lambda_layer_version.terraform_layer.arn]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda.function_name
  principal     = "s3.amazonaws.com"
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy-${terraform.workspace}"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::meu-lambda-bucket",
          "arn:aws:s3:::meu-lambda-bucket/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "iam:GetRole",
          "iam:PassRole",
          "s3:*",
          "dynamodb:*"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_lambda_layer_version" "terraform_layer" {
  layer_name          = "terraform_layer"
  filename = "./lambda_terraform_layer_function.zip"
  compatible_runtimes = ["python3.12"]
  description         = "A Lambda layer with Terraform binary"
}
