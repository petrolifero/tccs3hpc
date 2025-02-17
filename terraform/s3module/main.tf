resource "aws_s3_bucket" "use_on_tests" {
  bucket = "tcc-joao-${var.pure_identifier}"
}

resource "aws_s3_bucket" "use_to_results" {
  bucket = "results-joao-${var.pure_identifier}"
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy-${var.pure_identifier}"
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
        "Resource": concat( [
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_on_tests.bucket}/*"],
	  ["arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.use_to_results.bucket}/*"])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = var.role_name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


resource "aws_instance" "cluster" {
  count                       = var.cluster_size
  ami                         = var.cluster_ami
  instance_type               = var.cluster_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  iam_instance_profile = var.instance_profile
  associate_public_ip_address = true

}







