# Terraform AWS Deployment

This repo contains Terraform configurations for deploying infrastructure using reusable modules stored in [terraform-aws-modules](https://github.com/AlorCoda/terraform-aws-modules).

## Environments
- `dev` → development environment
- `prod` → production environment

## Usage
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
