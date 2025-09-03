terraform {
  required_version = "~> 6.0.0"

  backend "s3" {
    bucket         = "benji-tf-state-bucket-3rd"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile = true 
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC module
module "vpc" {
  source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/library/vpc?ref=v1.0.0"

  name   = "attah"
  cidr_block   = var.vpc_cidr
  public_subnets  = var.aws_subnet.public.id 
  private_subnets = var.aws_subnet.private.id 
}

# EC2 module
module "ec2" {
  source = "git::https://github.com//AlorCoda/terraform-aws-modules.git//modules/library/ec2?ref=v1.0.0"

  instance_type   = var.instance_type
  ami             = var.data.aws_ami.ubuntu.id
  subnet_id       = module.vpc.public_subnet_ids[1]
  security_groups = [module.security-group.security_group.web.id]
}

# Security Group module
module "sg" {
  source = "git::https://github.com//AlorCoda/terraform-aws-modules.git//modules/library/security-group?ref=v1.0.0"

  name        = "dev-sg"
  description = "Allowed HTTP/SSH"
  vpc_id      = data.aws_vpc.default.id
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}