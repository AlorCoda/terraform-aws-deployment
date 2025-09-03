output "cidr_block" {
  value = module.vpc.vpc_cidr
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "ec2_instance_id" {
  value = module.ec2.data.aws_ami.ubuntu.id
}

output "aws_security_group_id" {
  value = module.security-group.security_group.web.id 
}
