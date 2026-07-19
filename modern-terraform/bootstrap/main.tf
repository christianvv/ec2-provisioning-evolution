terraform {
  required_version = ">= 1.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create the S3 tf state Bucket and attributes
resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "epe-mt-terraform-state-01"

  # Enables terraform destroy to fully remove the bucket even with versioning
  # enabled and prior object versions present - needed for CI's repeatable
  # apply/destroy cycle. A real production state bucket would typically
  # leave this false to prevent accidental loss of state history.
  force_destroy = true

  tags = {
    Name    = "Terraform State Bucket"
    Purpose = "ec2-provisioning-evolution remote state"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_configuration" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
