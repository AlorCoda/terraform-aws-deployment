# terraform {
#   required_version = "~> 1.7.0"

#   backend "s3" {
#     bucket         = "benji-tf-state-bucket-3rd"
#     key            = "dev/terraform.tfstate"
#     region         = "us-west-2"
#     encrypt        = true 
#     # use_lockfile = true 
#   }
# }

# provider "aws" {
#   region = var.aws_region
# }

# # # VPC module
# # module "vpc" {
# #   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/vpc?ref=main"

# #   name   = "attah"
# #   cidr_block   = var.vpc_cidr
# #   public_subnets  = var.public_subnet_cidrs
# #   private_subnets = var.var.private_subnet_cidrs 
# # }

# # EC2 module
# # module "ec2" {
# #   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/ec2?ref=main"

# #   instance_type   = var.instance_type
# #   ami             = var.ami_id
# #   subnet_id       = module.vpc.public_subnet_ids[1]
# #   security_groups = [module.sg.security_group_id]
# # }


# # # Security Group module
# # module "sg" {
# #   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/security-group?ref=main"

# #   vpc_id      = module.vpc.vpc_id
# # }

# # VPC module (keep this if it works)
# module "vpc" {
#   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/vpc?ref=main"

#   name            = "attah"
#   cidr_block      = var.vpc_cidr
#   public_subnets  = var.public_subnet_cidrs
#   private_subnets = var.private_subnet_cidrs
# }

# # Security Group - using direct AWS resource
# resource "aws_security_group" "web_sg" {
#   name        = "dev-sg"
#   description = "Allowed HTTP/SSH"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "dev-sg"
#   }
# }

# # EC2 Instance - using direct AWS resource
# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = var.instance_type
#   subnet_id              = module.vpc.public_subnet_ids[0]
#   vpc_security_group_ids = [aws_security_group.web_sg.id]

#   tags = {
#     Name = "web-server"
#     Environment = "dev"
#   }
# }

# # Data source for latest Ubuntu AMI
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#     filter {
#     name   = "state"
#     values = ["available"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }

#   owners = ["099720109477"] # Canonical
# }


terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "benji-tf-state-bucket-3rd"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    use_lockfile = true 
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Benji"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/vpc?ref=v1.0.0"

  name               = "${var.project_name}-${var.environment}"
  cidr_block         = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = var.common_tags
}

# Web Security Group
module "web_security_group" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/security-group?ref=v1.0.0"

  name        = "${var.project_name}-${var.environment}-web"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "SSH from VPC"
    }
  ]

  tags = var.common_tags
}

# Database Security Group
module "db_security_group" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/security-group?ref=v1.0.0"

  name        = "${var.project_name}-${var.environment}-db"
  description = "Security group for database servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.web_security_group.security_group_id
      description              = "MySQL from web servers"
    }
  ]

  tags = var.common_tags
}

# Application Load Balancer Security Group
module "alb_security_group" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/security-group?ref=v1.0.0"

  name        = "${var.project_name}-${var.environment}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]

  tags = var.common_tags
}

# Web Servers
module "web_servers" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/ec2?ref=v1.0.0"

  name           = "${var.project_name}-${var.environment}-web"
  instance_count = var.web_instance_count
  instance_type  = var.web_instance_type
  
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.web_security_group.security_group_id]
  
  user_data = base64encode(templatefile("${path.module}/userdata/web_server.sh", {
    environment = var.environment
  }))

  tags = merge(var.common_tags, {
    Role = "WebServer"
  })
}

# Database Servers
module "database_servers" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/ec2?ref=v1.0.0"

  name           = "${var.project_name}-${var.environment}-db"
  instance_count = var.db_instance_count
  instance_type  = var.db_instance_type
  
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.db_security_group.security_group_id]

  tags = merge(var.common_tags, {
    Role = "Database"
  })
}

