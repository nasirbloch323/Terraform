# 🚀 Modular Terraform Infrastructure with Remote Backend (S3 + DynamoDB)

> Scalable, collaborative, and production-ready Infrastructure as Code (IaC) using **Terraform**, **AWS S3**, and **DynamoDB** — with full environment isolation for `dev`, `staging`, and `prod`.

![Terraform](https://img.shields.io/badge/Terraform-1.5.7+-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 📖 Table of Contents

- [Problem Statement](#-problem-statement)
- [Objectives](#-objectives)
- [Architecture Overview](#-architecture-overview)
- [Why Remote State? (S3)](#-why-s3-is-used-to-store-terraform-state)
- [Why State Locking? (DynamoDB)](#-why-dynamodb-is-used-for-locking)
- [Locking Strategies Compared](#-locking-strategies-s3-native-vs-dynamodb)
- [Project Structure](#-project-structure-industry-best-practices)
- [Prerequisites](#-prerequisites)
- [Step-by-Step Setup Guide](#-step-by-step-setup-guide)
  - [1. Install AWS CLI](#1️⃣-install-aws-cli)
  - [2. Configure AWS Credentials](#2️⃣-configure-aws-credentials)
  - [3. Install Terraform](#3️⃣-install-terraform)
  - [4. Bootstrap the Backend (S3 + DynamoDB)](#4️⃣-bootstrap-the-backend-s3--dynamodb)
  - [5. Configure Environment Backend](#5️⃣-configure-environment-backend)
  - [6. Deploy VPC & EC2 Modules](#6️⃣-deploy-vpc--ec2-modules)
- [Handling Errors & Stuck Locks](#-handling-errors--interruptions)
- [Terraform Import (Bringing Existing Infra Under Terraform)](#-terraform-import)
- [Expected Outcomes](#-expected-outcomes)
- [Conclusion](#-conclusion)

---

## 🛑 Problem Statement

As cloud infrastructure grows, managing Terraform state **locally** leads to:

- ❌ State file conflicts between engineers
- ❌ Loss of state history
- ❌ No real collaboration across a team
- ❌ Risk of accidental overwrites and corruption

**The Solution:** A modular Terraform architecture with a **remote backend on S3** for centralized state storage, plus **DynamoDB** for state locking — enabling safe, scalable, and collaborative infrastructure management.

---

## 🎯 Objectives

- ✅ Build a modular Terraform architecture for reusability and maintainability
- ✅ Store Terraform state securely and centrally in an S3 bucket
- ✅ Enable state locking with DynamoDB to prevent concurrent changes
- ✅ Improve collaboration across DevOps teams working on shared infrastructure
- ✅ Standardize deployments across environments (`dev`, `staging`, `prod`)
- ✅ Ensure infrastructure scalability, reusability, and auditability

---

## 🏗 Architecture Overview

**State & Locking Flow:**

```
Terraform CLI / Pipeline
        │
        ├── terraform plan / apply
        ▼
   ┌─────────────┐        ┌──────────────────┐
   │  S3 Bucket  │◄──────►│  DynamoDB Table   │
   │ (State File)│        │  (Lock Record)    │
   └─────────────┘        └──────────────────┘

1. Acquire Lock → 2. Apply Changes → 3. Release Lock
```

**Network Architecture (VPC Module):**

```
VPC (10.0.0.0/16)
 ├── Internet Gateway
 ├── Public Subnet
 │     └── Bastion EC2 (public IP, SSH from internet)
 ├── NAT Gateway (in public subnet)
 └── Private Subnet
       └── Private EC2s (no public IP, SSH only via bastion)
```

---

## 🪣 Why S3 is Used to Store Terraform State

Terraform needs a **central source of truth** to track real infrastructure (IDs, ARNs, IPs, etc.). S3 provides:

| Benefit | Description |
|---|---|
| **Central shared storage** | Team & CI/CD can access the same state |
| **Durability** | 11 nines (99.999999999%) durability — data loss is virtually impossible |
| **Versioning** | Roll back if the state file ever breaks |
| **Encryption** | AES-256 or KMS at rest |
| **Access control** | Fine-grained permissions via IAM |

> If state were kept locally → it would be inconsistent, corruptible, impossible to roll back, and unusable in CI/CD.

---

## 🔒 Why DynamoDB is Used for Locking

Terraform must prevent **simultaneous changes** to the same state file (e.g., two `apply` commands running at once). DynamoDB provides:

- 🔐 **State locking** — only one apply runs at a time
- ✅ **Consistency** — avoids race conditions
- 🔄 **Automatic unlocking** on completion

> **What's a race condition?** When two or more processes access and modify the same resource simultaneously, causing unpredictable or incorrect results.

**📌 Key Idea:** S3 stores the Terraform state. DynamoDB ensures only one Terraform run modifies it at a time.

### ✔ Advantages of DynamoDB Locking

| Benefit | Explanation |
|---|---|
| Prevents corruption | No two applies can modify state at once |
| Safe for CI/CD | Works with GitHub Actions, Jenkins, GitLab |
| Durable | AWS handles HA & durability |
| Cheap | Often < $1/month |
| Native | No extra components needed beyond the table |

---

## ⚖️ Locking Strategies: S3-Native vs. DynamoDB

### 1️⃣ DynamoDB Locking (Traditional)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
```

**Pros:** battle-tested, high concurrency support, robust in edge cases.
**Cons:** needs an extra AWS resource, more IAM setup, locking is external to the state file.

### 2️⃣ S3 Native Locking (Terraform v1.10+)

```hcl
terraform {
  backend "s3" {
    bucket       = "my-tf-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

**Pros:** no DynamoDB table needed, simpler IAM, great for small/medium teams.
**Cons:** less battle-tested at very high concurrency, requires S3 versioning for safe recovery.

### 📊 Quick Comparison

| Feature | S3 Locking (Native) | DynamoDB Locking |
|---|---|---|
| Terraform version | 1.10+ | Any |
| Extra service required | ❌ | ✅ DynamoDB table |
| Concurrency robustness | Medium | High |
| Setup complexity | Low | Medium |
| Best for | Small/medium teams | Large teams / enterprise |
| Disaster recovery | S3 versioning required | Built-in |
| Long-term support | Newer / evolving | Mature / widely adopted |

**✅ Rule of thumb:**
- Small/medium team, simple setup → use **S3-native locking** (`use_lockfile = true`)
- Enterprise, high concurrency, production-critical → stick with **S3 + DynamoDB**

> 💡 **Tip:** Even with S3-native locking, always enable S3 versioning — it helps recover state if a lock ever fails.

---

## 📂 Project Structure (Industry Best Practices)

```
terraform-infra/
│
├── bootstrap/                  # One-time setup for backend infra
│   ├── main.tf
│   ├── provider.tf
│   ├── s3.tf
│   ├── dynamodb.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── modules/                     # Reusable Terraform modules
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/                # Environment-specific configs
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
│
└── README.md
```

### ✅ Why This Structure is Best Practice

| Reason | Explanation |
|---|---|
| **Encapsulation** | Each module is self-contained — everything needed to deploy it lives inside |
| **Reusability** | The EC2 module can be reused across `dev`, `staging`, `prod` without copying code |
| **Version control clarity** | Changes to scripts are versioned along with the module |
| **CI/CD compatibility** | Pipelines reuse the same module without fetching external files |
| **Security** | Prevents path leaks or referencing scripts from arbitrary directories |

---

## 📋 Prerequisites

Before running Terraform, make sure you have:

- ✅ An AWS account with permissions for **EC2**, **S3**, and **IAM**
- ✅ AWS CLI installed and configured
- ✅ Terraform installed (v1.5.7 or later)

---

## 🛠 Step-by-Step Setup Guide

### 1️⃣ Install AWS CLI

```bash
# Update packages
sudo apt update

# Install dependencies
sudo apt install unzip curl -y

# Download the AWS CLI v2 bundle
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the installer
unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Verify installation
aws --version
```

### 2️⃣ Configure AWS Credentials

Generate an Access Key from **AWS Console → IAM → Users → Security credentials → Create access key**, then run:

```bash
aws configure
```

You'll be prompted for:

```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: ********************************
Default region name [None]: us-east-1
Default output format [None]: json
```

> ⚠️ Never commit real access keys to version control. Use IAM roles or environment variables in CI/CD.

### 3️⃣ Install Terraform

```bash
sudo apt-get update -y
sudo apt-get install -y wget unzip

wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/

terraform -version
```

### 4️⃣ Bootstrap the Backend (S3 + DynamoDB)

The `bootstrap/` folder creates the S3 bucket and DynamoDB table used by every environment. It intentionally uses a **local backend** since the S3 bucket doesn't exist yet.

**`bootstrap/terraform.tfvars`**

```hcl
region               = "us-east-1"
bucket_name          = "my-terraform-state-bucket-123"
dynamodb_table_name  = "terraform-state-locks"
```

**Run it:**

```bash
cd bootstrap
terraform init
terraform apply -auto-approve
```

This provisions:
- An **S3 bucket** with versioning + AES-256 encryption enabled
- A **DynamoDB table** (`PAY_PER_REQUEST` billing, `LockID` as hash key) for state locking

### 5️⃣ Configure Environment Backend

Once bootstrap is complete, point each environment (`dev`, `staging`, `prod`) at the new remote backend.

**`environments/dev/backend.tf`**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-123"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### 6️⃣ Deploy VPC & EC2 Modules

From inside an environment folder (e.g., `environments/dev`):

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**What gets created:**

- 🌐 **VPC** with public + private subnets across multiple Availability Zones
- 🌍 **Internet Gateway** for public subnet internet access
- 🔁 **NAT Gateway** so private subnets can reach the internet outbound-only
- 🖥 **Bastion EC2** in the public subnet (SSH accessible from the internet)
- 🔒 **Private EC2s** with no public IP — SSH only permitted from the bastion host
- 🧩 Fully dynamic subnet handling using `for_each` — add more subnets and Terraform adjusts automatically, no hardcoded indexes

---

## 🧯 Handling Errors & Interruptions

If Terraform crashes mid-run (network drop, `Ctrl+C`, CI failure), the lock **remains** in DynamoDB to protect state integrity. To release it manually:

```bash
terraform force-unlock <LOCK-ID>
```

This deletes the stale lock record and restores consistency — no state corruption, even after failures.

---

## 📥 Terraform Import

`terraform import` lets Terraform take control of **existing** AWS resources — created manually in the console, via CloudFormation/CDK, by scripts, or by another team member — **without recreating them**.

```bash
# 1. Define an empty resource block
resource "aws_instance" "my_ec2" {
  # fill in after import
}

# 2. Import the real resource by ID
terraform import aws_instance.my_ec2 i-0123456789abcdef0
```

### ⭐ Advantages
- Take control of existing infra with **zero downtime**
- Modernizes manual/GUI-managed resources into IaC
- Enables change history, code review, and version control
- Detects and helps correct **drift** between code and real infrastructure

### ⚠️ Disadvantages
- Doesn't auto-generate configuration — you must write it manually
- Tedious at scale (200+ resources)
- Not every AWS resource type is importable
- Risk of drift-driven replacement if `.tf` config doesn't exactly match the real resource
- Dependency order matters (e.g., import VPC → subnets → route tables → gateways, in that order)

### 🤔 When to Use It

| Use it when... | Avoid it when... |
|---|---|
| You have existing infra you can't delete | It's easier to destroy & recreate (e.g. throwaway dev resources) |
| You want to modernize into IaC | Infra is too massive — consider export/convert tooling instead |
| You need collaboration + version control | — |

---

## 📈 Expected Outcomes

- 🤝 **Improved Collaboration** — centralized state lets engineers and CI/CD systems work safely together
- 🛡 **Eliminated State Corruption** — DynamoDB locks enforce safe concurrency
- ♻️ **Reusability & Standardization** — modules give consistent infra across environments
- 🔍 **Auditability & Traceability** — versioned state history in S3
- 📊 **Scalability** — infrastructure and modules grow with the organization
- 🔐 **Security** — encrypted, IAM-controlled backend storage

---

## 📍 Conclusion

Modular Terraform with a remote backend backed by **S3 + DynamoDB** delivers a scalable, secure, and collaborative approach to Infrastructure as Code. It removes the risks of local state files, plugs cleanly into automation pipelines, and enforces industry-grade best practices for DevOps teams managing cloud infrastructure at scale.

---

## 📎 Repository

Clone this project:

```bash
git clone https://github.com/nasirbloch323/terraform
```

---

## 🧑‍💻 Author

Built as a hands-on DevOps/Cloud learning project — feel free to fork, star ⭐, and contribute!
