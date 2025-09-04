terraform {
  required_version = "~> 1.7.0"

  backend "s3" {
    bucket         = "benji-tf-state-bucket-3rd"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true 
    # use_lockfile = true 
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC module
module "vpc" {
  source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/vpc?ref=main"

  name   = "attah"
  cidr_block   = var.vpc_cidr
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.var.private_subnet_cidrs 
}

# EC2 module
module "ec2" {
  source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/ec2?ref=main"

  # instance_type   = var.instance_type
  # ami             = var.ami_id
  # subnet_id       = module.vpc.public_subnet_ids[1]
  # security_groups = [module.sg.security_group_id]
  
  instance_type    = var.instance_type
  image_id        = data.aws_ami.ubuntu.id      # instead of 'ami'
  subnet          = module.vpc.public_subnet_ids[0]  # instead of 'subnet_id'
  security_group_ids = [aws_security_group.web_sg.id]  # instead of 'security_groups'

}

# Security Group module
module "sg" {
  source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/security-group?ref=main"

  name        = "dev-sg"
  description = "Allowed HTTP/SSH"
  vpc_id      = module.vpc.vpc_id
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

    filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical
}


