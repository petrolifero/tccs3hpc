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
  for_each=toset(local.s3_array)
  instanceType=each.value.instance_type
}

module "fsx" {
  source = "./fsxmodule"
  for_each=toset(local.other_modes)
  instanceType=each.value.instance_type
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

locals {
         parsed_array = jsondecode(var.config)
	   s3_array     = [for item in local.parsed_array : item if item.mode == "s3"]
	     other_modes  = [for item in local.parsed_array : item if item.mode != "s3"]
	 
}