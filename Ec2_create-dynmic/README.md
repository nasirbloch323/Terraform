# Terraform AWS EC2 Provisioning

Terraform configuration to provision AWS EC2 instances with a key pair and security group inside the default VPC.

## What it creates

- **Key Pair** — from local `nasir.pub` file
- **Security Group** — SSH access + all outbound traffic
- **EC2 Instances** — configurable count, in default VPC/subnet

## Project Structure

```
.
├── provider.tf     # AWS provider config
├── variables.tf    # Input variables
├── main.tf         # Key pair, SG, subnets, EC2 resources
├── outputs.tf      # Output values
├── terraform.tfvars# Variable values
└── nasir.pub       # SSH public key
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with valid credentials

```bash
aws configure
aws sts get-caller-identity   # verify credentials
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Name              | Description                  | Default     |
|-------------------|-------------------------------|-------------|
| `region`          | AWS region                   | `us-east-1` |
| `key_name`        | Key pair name                | —           |
| `sg_name`         | Security group name          | —           |
| `env`             | Environment tag               | —           |
| `ssh_cidr`        | Allowed CIDR for SSH          | —           |
| `instance_count`  | Number of EC2 instances       | `1`         |
| `ami`             | AMI ID                        | —           |
| `instance_type`   | EC2 instance type             | `t2.micro`  |

Set these in `terraform.tfvars` before running `apply`.

## Outputs

- `key_name` — key pair name
- `public_ip` — public IP(s) of instances
- `instance_id` — instance ID(s)
- `security_group_id` — security group ID

## Destroy

```bash
terraform destroy
```

## Notes

- Ensure `nasir.pub` is in the same directory as the `.tf` files.
- For production, restrict `ssh_cidr` to your own IP instead of `0.0.0.0/0`.
