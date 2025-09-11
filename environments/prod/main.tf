# terraform {
#   required_version = "~> 1.7.0"

#   backend "s3" {
#     bucket         = "benji-tf-state-bucket-3rd"
#     key            = "prod/terraform.tfstate"
#     region         = "us-west-2"
#     use_lockfile = true 
#   }
# }

# provider "aws" {
#   region = var.aws_region
# }

# # VPC module
# module "vpc" {
#   source = "git::https://github.com/AlorCoda/terraform-aws-modules.git//modules/vpc?ref=main"

#   name   = "attah"
#   cidr_block   = var.vpc_cidr
#   public_subnets  = var.aws_subnet.public.id 
#   private_subnets = var.aws_subnet.private.id 
# }

# # EC2 module
# module "ec2" {
#   source = "git::https://github.com//AlorCoda/terraform-aws-modules.git//modules/ec2?ref=main"

#   instance_type   = var.instance_type
#   ami             = var.data.aws_ami.ubuntu.id
#   subnet_id       = module.vpc.public_subnet_ids[1]
#   security_groups = [module.security-group.security_group.web.id]
# }

# # Security Group module
# module "sg" {
#   source = "git::https://github.com//AlorCoda/terraform-aws-modules.git//modules/security-group?ref=main"

#   name        = "pod-sg"
#   description = "Allowed HTTP/SSH"
#   vpc_id      = data.aws_vpc.default.id
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
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Benji"
      CostCenter    = "Production"
      Backup        = "Required"
      Monitoring    = "Critical"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
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

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# VPC Module
module "vpc" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/vpc?ref=v1.0.0"

  name               = "${var.project_name}-${var.environment}"
  cidr_block         = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3) # Use 3 AZs for production
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.common_tags
}

# VPC Flow Logs for monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn

  tags = var.common_tags
}

resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
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

  egress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "All traffic to VPC"
    }
  ]

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
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "HTTP from ALB"
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "HTTPS from ALB"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.bastion_cidr]
      description = "SSH from bastion host"
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
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.web_security_group.security_group_id
      description              = "PostgreSQL from web servers"
    }
  ]

  tags = var.common_tags
}

# Bastion Host Security Group
module "bastion_security_group" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/security-group?ref=v1.0.0"

  name        = "${var.project_name}-${var.environment}-bastion"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidrs
      description = "SSH from allowed IPs"
    }
  ]

  tags = var.common_tags
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_security_group.security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = var.common_tags
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-${var.environment}-alb-logs-${random_string.bucket_suffix.result}"
  force_destroy = false

  tags = var.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::797873946194:root" # ELB service account for us-west-2
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = var.common_tags
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Bastion Host
module "bastion_host" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/ec2?ref=v1.0.0"

  name           = "${var.project_name}-${var.environment}-bastion"
  instance_count = 1
  instance_type  = "t3.nano"
  key_name       = var.key_name
  
  subnet_ids         = [module.vpc.public_subnet_ids[0]] # Single bastion in first AZ
  security_group_ids = [module.bastion_security_group.security_group_id]

  root_volume_encrypted = true
  root_volume_size      = 8

  user_data = base64encode(templatefile("${path.module}/userdata/bastion_server.sh", {
    environment = var.environment
  }))

  tags = merge(var.common_tags, {
    Role = "BastionHost"
  })
}

# Web Servers with Auto Scaling
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [module.web_security_group.security_group_id]

  user_data = base64encode(templatefile("${path.module}/userdata/web_server.sh", {
    environment     = var.environment
    project_name    = var.project_name
    db_endpoint     = module.database_servers.instance_private_ips[0]
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.main.arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Role = "WebServer"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = module.vpc.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = var.web_min_size
  max_size         = var.web_max_size
  desired_capacity = var.web_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Database Servers
module "database_servers" {
  source = "git::https://github.com/username/terraform-aws-modules.git//modules/ec2?ref=v1.0.0"

  name           = "${var.project_name}-${var.environment}-db"
  instance_count = var.db_instance_count
  instance_type  = var.db_instance_type
  key_name       = var.key_name
  
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.db_security_group.security_group_id]

  root_volume_encrypted = true
  root_volume_size      = 50
  root_volume_type      = "gp3"

  user_data = base64encode(templatefile("${path.module}/userdata/database_server.sh", {
    environment  = var.environment
    project_name = var.project_name
  }))

  tags = merge(var.common_tags, {
    Role   = "Database"
    Backup = "Daily"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = var.common_tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-${var.environment}-alerts"
  display_name = "Production Alerts"
  kms_master_key_id = aws_kms_key.main.arn

  tags = var.common_tags
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Scale up when CPU > 75%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "25"
  alarm_description   = "Scale down when CPU < 25%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = var.common_tags
}