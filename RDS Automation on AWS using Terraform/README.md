# 🔐 Secure & Scalable RDS Automation on AWS using Terraform

Automate the provisioning and management of Amazon RDS (MySQL) using **Terraform**, following AWS best practices for security, high availability, and Infrastructure as Code (IaC).

---

## 📌 Problem Statement

Managing relational databases on AWS RDS manually through the AWS Console is time-consuming, error-prone, and difficult to standardize across environments. Common challenges include:

- Inconsistent database configurations between dev, staging, and production
- Weak or misconfigured security groups and database credentials
- Manual backup, monitoring, and maintenance configuration
- Difficulty scaling database infrastructure as applications grow
- Limited auditability and poor change tracking for database infrastructure

Manual RDS management increases operational overhead, introduces security and availability risks, and makes compliance and disaster recovery harder to maintain.

---

## 🎯 Objective

Automate provisioning and management of Amazon RDS using Terraform, ensuring:

- ✅ Secure and standardized RDS deployments following AWS best practices
- ✅ Consistent database configurations across all environments
- ✅ Automated backups, maintenance windows, and monitoring
- ✅ Scalable and highly available database infrastructure
- ✅ Version-controlled and auditable infrastructure-as-code

---

## 👤 DevOps / Cloud Engineer Use Case

As a DevOps or Cloud Engineer, this project lets you:

- Automatically provision RDS instances using Terraform
- Define database engine, version, instance size, and storage declaratively
- Secure databases using private subnets and security groups
- Enable automated backups, Multi-AZ deployments, and monitoring
- Manage credentials securely and consistently
- Maintain a single source of truth for database infrastructure

### Example Scenario

A web application requires a MySQL database backend. Using Terraform, you:

1. Create an RDS MySQL instance in private subnets
2. Enable Multi-AZ for high availability
3. Configure automated backups and maintenance windows
4. Apply security groups allowing access only from application servers
5. Store database configuration in version control for auditing

Terraform ensures the same database setup is deployed reliably across dev, staging, and production environments.

---

## 🗂 Project Structure

```
terraform-rds/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
│
├── modules/
│   └── rds/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   ├── stage/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       └── outputs.tf
```

---

## 📥 Clone the Repository

```bash
git clone https://github.com/Umair1061/terraform-rds
cd terraform-rds
```

---

## ✅ Prerequisites

Before running Terraform, make sure you have:

- ✅ An AWS Account with permissions for EC2, S3, RDS, and IAM
- ✅ AWS CLI installed and configured
- ✅ Terraform installed

---

## 🛠 Step-by-Step Setup

### Step 1 — Install AWS CLI

```bash
# 1. Update packages
sudo apt update

# 2. Install dependencies
sudo apt install unzip curl -y

# 3. Download the AWS CLI v2 bundle
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 4. Unzip the installer
unzip awscliv2.zip

# 5. Run the installer
sudo ./aws/install

# 6. Verify installation
aws --version
```

### Step 2 — Get AWS Credentials

You'll need an **Access Key ID** and **Secret Access Key**. To generate them:

1. Go to the AWS Console
2. Open **IAM > Users >** click your username
3. Go to **Security credentials**
4. Click **Create access key**
5. Copy the Access Key ID and Secret Access Key

> ⚠️ Never commit these credentials to version control.

### Step 3 — Run `aws configure`

```bash
aws configure
```

You'll be prompted for:

```
AWS Access Key ID [None]: <your-access-key-id>
AWS Secret Access Key [None]: <your-secret-access-key>
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 4 — Install Terraform (Ubuntu / Debian)

```bash
sudo apt-get update -y
sudo apt-get install -y wget unzip

wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/

terraform -version
```

---

## ⚙️ Configuration

### `environments/dev/terraform.tfvars`

Update this file with your own values before running Terraform:

```hcl
vpc_id      = "vpc-123abc"
subnet_ids  = ["subnet-abc123", "subnet-def456"]
db_username = "admin"
db_password = "StrongPassword123!"
```

> 🔒 **Security tip:** Don't commit real secrets to Git. Use a `.gitignore` entry for `*.tfvars`, or better, manage `db_password` via **AWS Secrets Manager**, **SSM Parameter Store**, or environment variables with `TF_VAR_db_password`.

### Key Variables (`variables.tf`)

| Variable        | Description                          | Default        |
|-----------------|---------------------------------------|-----------------|
| `aws_region`    | AWS region                            | `us-east-1`     |
| `vpc_id`        | VPC where RDS will be deployed        | *(required)*    |
| `subnet_ids`    | Private subnet IDs for subnet group   | *(required)*    |
| `db_name`       | Initial database name                 | `appdb`         |
| `db_username`   | Master DB username                    | *(required)*    |
| `db_password`   | Master DB password (sensitive)        | *(required)*    |
| `allowed_cidr`  | CIDR block allowed to access MySQL    | `10.0.0.0/16`   |
| `environment`   | Deployment environment name           | `dev`           |

---

## 🚀 Terraform Workflow

Run these commands from the relevant `environments/<env>` directory (e.g. `environments/dev`).

### Step 1 — Initialize

```bash
terraform init
```

Downloads the AWS provider and sets up the backend.

### Step 2 — Plan

```bash
terraform plan
```

Shows exactly what Terraform will create/change before applying.

### Step 3 — Apply

```bash
terraform apply
```

Provisions the RDS subnet group, security group, and MySQL instance. Confirm with `yes` when prompted.

### Step 4 — View Outputs

```bash
terraform output
```

Displays the RDS endpoint, instance identifier, and security group ID.

### Step 5 — Destroy (Optional)

```bash
terraform destroy
```

Tears down all resources created by this configuration. Use with caution in shared/prod environments.

---

## 🏗 What Gets Provisioned

- **`aws_db_subnet_group`** — Places RDS across private subnets in multiple AZs
- **`aws_security_group`** — Restricts MySQL (port 3306) access to an internal CIDR only
- **`aws_db_instance`** — MySQL 8.0 instance with:
  - Multi-AZ enabled for high availability
  - `publicly_accessible = false`
  - Automated backups (7-day retention)
  - Defined backup and maintenance windows
  - GP3 storage for cost-efficient performance

---

## 🌍 Multi-Environment Support (Module-Based)

This project uses a reusable `modules/rds` module consumed by `environments/dev`, `environments/stage`, and `environments/prod`, so the same database blueprint can be promoted across environments with different variable values (CIDR, credentials, instance size, etc.).

```hcl
module "rds" {
  source       = "../../modules/rds"
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids
  db_name      = "appdb"
  db_username  = var.db_username
  db_password  = var.db_password
  allowed_cidr = "10.0.0.0/16"
  environment  = "dev"
}
```

For `prod`, use the same structure with:
- `environment = "prod"`
- A narrower `allowed_cidr`
- A stronger, secrets-manager-sourced password
- A larger `instance_class` as load grows

---

## ✅ Why This Structure Is Production-Ready

- ✔ Clean separation of concerns (root, module, environments)
- ✔ Secure handling of secrets via `sensitive = true` variables
- ✔ Multi-AZ enabled for high availability
- ✔ Reusable, DRY Terraform module
- ✔ Clean blast radius — changes in one environment don't affect others
- ✔ Easy promotion path: dev → stage → prod
- ✔ Matches how real companies structure IaC repos

---

## 📈 Expected Outcomes

- Fully automated provisioning of RDS databases using Terraform
- Secure and standardized database deployments
- High availability with Multi-AZ configuration
- Automated backups and predictable maintenance
- Reduced downtime and operational risk
- Version-controlled, auditable database infrastructure

---

## ⚠️ Recommended Hardening Before Production Use

- Store `db_password` in **AWS Secrets Manager** or **SSM Parameter Store** instead of `terraform.tfvars`
- Set `deletion_protection = true` and `skip_final_snapshot = false` for prod
- Enable `storage_encrypted = true`
- Enable **Enhanced Monitoring** and **Performance Insights**
- Use remote state (S3 + DynamoDB lock table) instead of local state
- Restrict `allowed_cidr` to the smallest possible range

---

## 🏁 Conclusion

Automating Amazon RDS with Terraform provides a secure, scalable, and repeatable approach to managing relational databases on AWS. By adopting Infrastructure as Code:

- Database environments are consistent and reproducible
- Security, availability, and backup best practices are enforced
- Infrastructure changes are auditable and reversible
- DevOps teams can manage databases efficiently without manual intervention

This approach forms a strong foundation for production-ready, compliant, and highly available database infrastructure in modern cloud architectures.

---

## 📄 License

This project is provided as-is for educational and portfolio purposes.