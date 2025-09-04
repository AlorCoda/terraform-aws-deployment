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
# module "ec2" {
#   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/ec2?ref=main"

#   instance_type   = var.instance_type
#   ami             = var.ami_id
#   subnet_id       = module.vpc.public_subnet_ids[1]
#   security_groups = [module.sg.security_group_id]
# }


# # Security Group module
# module "sg" {
#   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/security-group?ref=main"

#   vpc_id      = module.vpc.vpc_id
# }

# VPC module (keep this if it works)
module "vpc" {
  source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/vpc?ref=main"
  name            = "attah"
  cidr_block      = var.vpc_cidr
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
}

# Security Group - using direct AWS resource
resource "aws_security_group" "web_sg" {
  name        = "dev-sg"
  description = "Allowed HTTP/SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg"
  }
}

# EC2 Instance - using direct AWS resource
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-server"
    Environment = "dev"
  }
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


