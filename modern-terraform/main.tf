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

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  admin_cidr           = var.admin_cidr
}

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  instances             = var.instances
  private_subnet_ids    = module.networking.private_subnet_ids
  private_compute_sg_id = module.networking.private_compute_sg_id
}
