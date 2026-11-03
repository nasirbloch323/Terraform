# Week 3 — Modular Terraform Architecture & Ansible Integration

**Project:** CypherNex DevOps Internship — Project 2  
**Trainee:** Nasir Mehmood  
**Milestone:** Week 3 — Modularization, Variable Validation & Ansible Foundation

## 1. Project Objective

The objective of Week 3 is to refactor the existing Terraform EC2 provisioning code into a reusable, production-oriented modular architecture, introduce variable validation safeguards, and prepare Ansible for post-provisioning configuration management.

The infrastructure is organized into independent Terraform modules. The root module connects these modules and passes validated configuration values.

## 2. Architecture

```text
week3-modular-architecture/
├── main.tf
├── providers.tf
├── versions.tf
├── data.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security_group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── ansible/
    ├── ansible.cfg
    ├── inventory.ini.tftpl
    └── playbook.yml
```

| Module | Responsibility |
|---|---|
| `vpc` | VPC, public subnet, Internet Gateway and public route table |
| `security_group` | SSH ingress restricted to a trusted CIDR, HTTP ingress and outbound access |
| `ec2` | EC2 instance, SSH key pair and encrypted gp3 root volume |
| `ansible` | Generated host inventory and baseline Nginx configuration |

## 3. Infrastructure Design

- AWS provider region is configurable; the example uses `us-east-2`.
- VPC CIDR: `10.30.0.0/16`.
- Public subnet CIDR: `10.30.1.0/24`.
- Ubuntu 24.04 LTS AMI is discovered dynamically from Canonical's AWS account instead of relying on a hardcoded AMI ID.
- EC2 uses a configurable instance type and an encrypted gp3 root volume.
- IMDSv2 is required for instance metadata access.
- AWS resources receive common project, environment and management tags.

## 4. Variable Validation & Security Guardrails

Terraform validation blocks help reject unsafe or invalid input before infrastructure is created.

| Variable | Validation |
|---|---|
| `project_name` | 3–20 characters; lowercase letters, numbers and hyphens |
| `environment` | Only `dev`, `staging` or `prod` |
| `aws_region` | AWS region-style format |
| `vpc_cidr` | Must be a valid IPv4 CIDR |
| `public_subnet_cidr` | Must be a valid IPv4 CIDR |
| `instance_type` | Restricted to the configured t2/t3 micro, small and medium allow-list |
| `root_volume_size` | Between 8 and 100 GiB |
| `ssh_allowed_cidr` | Must be a valid IPv4 CIDR; `0.0.0.0/0` is rejected |
| `ssh_public_key` | Must look like an OpenSSH public key |

**Important assignment alignment note:** The Week 3 submission brief specifically calls for an `instance_count` validation from 1 to 5 and an instance-type allow-list of only `t2.micro` and `t3.micro`. The current Terraform implementation provisions one EC2 instance and uses a broader t2/t3 allow-list. Add those two exact constraints before presenting this implementation as fully matching that acceptance criterion.

Security practices:
- Do not expose SSH to the entire internet. Set your own public IPv4 address with a `/32` mask.
- Never commit an SSH private key or real `terraform.tfvars` file.
- The generated Ansible inventory is excluded from Git and written with restrictive file permissions.
- Review the Terraform plan before applying resources.

## 5. Requirements

- Terraform CLI >= 1.5
- AWS CLI configured with credentials and permissions to create VPC, EC2, key-pair and security-group resources
- An SSH key pair on the machine running Terraform
- Ansible installed on the machine running the playbook

## 6. Configuration

Run the following commands from this project directory:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace the example SSH CIDR with your public IP:

```bash
curl -4 https://checkip.amazonaws.com
```

For example, use `YOUR_PUBLIC_IP/32` for `ssh_allowed_cidr`.

Export your SSH public key as an environment variable:

```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

Set `private_key_path` in `terraform.tfvars` to the matching private-key path if it differs from the default.

## 7. Terraform Execution Workflow

Initialize providers and modules:

```bash
terraform init
```

Format and validate the configuration:

```bash
terraform fmt -recursive
terraform validate
```

Review the execution plan:

```bash
terraform plan
```

Create the infrastructure after reviewing the plan:

```bash
terraform apply
```

Terraform provisions the network and EC2 resources and generates `ansible/inventory.ini` using the instance's public IP.

## 8. Ansible Integration

The Ansible playbook connects to the Terraform-provisioned Ubuntu server over SSH and performs baseline configuration.

Tasks included:
1. Wait for SSH connectivity.
2. Refresh the APT package cache.
3. Install Nginx.
4. Enable and start the Nginx service.
5. Publish a simple test landing page.

Run Ansible from the project directory:

```bash
ansible -i ansible/inventory.ini web -m ping
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

After the playbook succeeds, open the EC2 public IP in a browser to verify the Nginx page.

## 9. Cleanup

To avoid ongoing AWS charges, destroy the lab resources when testing is complete:

```bash
terraform destroy
```

Review the destroy plan and confirm before proceeding.

## 10. Week 3 Deliverables

- [x] Root Terraform configuration
- [x] Reusable VPC module
- [x] Reusable Security Group module
- [x] Reusable EC2 module
- [x] Input validation safeguards
- [x] Dynamic Ubuntu AMI lookup
- [x] Encrypted EC2 root volume and IMDSv2
- [x] Terraform-generated Ansible inventory
- [x] Ansible playbook for Nginx baseline setup
- [ ] Match the assignment's exact EC2 count (1–5) and Free Tier instance allow-list (`t2.micro`, `t3.micro`)
- [ ] Run and record `terraform init`, `terraform validate`, `terraform plan`, `terraform apply`, Ansible verification and `terraform destroy` in the target AWS account

## 11. Production Hardening — Next Improvements

This is a production-oriented learning foundation, not a complete production deployment. Before real production use, add private application subnets, multi-AZ architecture, remote encrypted Terraform state and locking, IAM least privilege, monitoring and alerts, backup policy, and a secure management path such as AWS Systems Manager Session Manager. Restrict HTTP behind a load balancer where appropriate.
