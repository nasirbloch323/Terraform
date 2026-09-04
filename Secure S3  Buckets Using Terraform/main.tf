provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "terraform-nasir-s3" # bucket name (underscores not allowed in S3 names)

  tags = { # optional but good practice
    Project     = "TerraformS3"
    Owner       = "DevOpsTeam"
    Name        = "terraform-demo-bucket-dev"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "version" { # enable/disable versioning
  bucket = aws_s3_bucket.mybucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# Encryption
############################################
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# Block Public Access
############################################
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.mybucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# Outputs
############################################
output "bucket_name" {
  value = aws_s3_bucket.mybucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.mybucket.arn
}
