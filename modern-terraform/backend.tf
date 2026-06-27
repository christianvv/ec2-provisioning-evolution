terraform {
  backend "s3" {
    bucket       = "epe-mt-terraform-state-01"
    key          = "modern-terraform/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
