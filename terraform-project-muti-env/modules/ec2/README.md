# Multi-Environment EC2 Provisioning with Terraform

Terraform ke zariye AWS EC2 instances ko **Dev, Staging aur Production** environments mein automate karne ka project. Yeh README aise likha gaya hai ke agar aap Terraform mein bilkul naye bhi hain, to bhi step by step follow karke poora project samajh aur run kar sakein.

---

## 📌 Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Project Objective](#2-project-objective)
3. [Two Approaches: Workspaces vs Separate Repos](#3-two-approaches-workspaces-vs-separate-repos)
4. [Prerequisites](#4-prerequisites)
5. [AWS CLI Install & Configure](#5-aws-cli-install--configure)
6. [Terraform Install](#6-terraform-install)
7. [Folder Structure](#7-folder-structure)
8. [EC2 Module Explanation](#8-ec2-module-explanation)
9. [Environment Setup (Dev/Stg/Prod)](#9-environment-setup-devstgprod)
10. [Step-by-Step: Kaise Run Karein](#10-step-by-step-kaise-run-karein)
11. [Best Practices](#11-best-practices)
12. [Outcomes](#12-outcomes)
13. [Next Steps](#13-next-steps)

---

## 1. Problem Statement

Jab EC2 instances ko manually AWS Console se create kiya jata hai, to yeh problems aati hain:

- Har environment (Dev, Stg, Prod) mein configuration alag ho jati hai
- Human error ka risk zyada hota hai (galat AMI, galat security group, etc.)
- Scale karna ya maintain karna mushkil ho jata hai
- Koi version control nahi hota — kisi ne kya change kiya, pata nahi chalta

**Solution:** Terraform (Infrastructure as Code tool) use karke poora provisioning process automate aur standardize kiya jaye.

---

## 2. Project Objective

Yeh project yeh cheezein achieve karta hai:

- ✅ Dev, Stg aur Prod mein `t2.micro` EC2 instance provision karta hai
- ✅ Modular architecture use karta hai (code reusable hai)
- ✅ Key pair aur security group automatically create karta hai
- ✅ Environment separation ka proper Terraform workflow demonstrate karta hai

---

## 3. Two Approaches: Workspaces vs Separate Repos

Terraform mein multiple environments manage karne ke do tareeqe hote hain. Dono ka farq samajhna zaroori hai:

### Approach A — Terraform Workspaces

Same code, alag state files. Environment switch karne ke liye command use hoti hai:

```bash
terraform init
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform apply
```

**Kab use karein:** Chhoti teams, POC (proof of concept), simple learning projects.

**Risk:** Agar galti se wrong workspace select ho jaye (jaise `prod` ke bajaye kuch aur), to deployment galat environment mein chali jaegi. Isliye production ke liye yeh 100% safe nahi.

### Approach B — Separate Repos / Folders

Har environment ka apna alag folder (ya repo), apna code, apna state, apna access control.

**Kab use karein:** Enterprise-level projects, multiple teams, production systems jahan security aur isolation important ho.

### Quick Comparison

| Cheez | Workspaces | Separate Repos |
|---|---|---|
| Code | Same | Alag |
| State | Alag (same repo mein) | Poori tarah alag |
| Setup Speed | Fast | Thoda slow |
| Safety | Kam (risk of wrong env) | Zyada (full isolation) |
| Best For | Small teams / POC | Large orgs / Production |

Is project mein humne **dono approaches** dikhayi hain — pehle workspaces se simple example, phir proper separate-folder structure se real-world setup.

---

## 4. Prerequisites

Project run karne se pehle yeh cheezein chahiye:

- AWS Account jisme EC2, S3 aur IAM permissions ho
- AWS CLI installed aur configured
- Terraform installed
- Basic terminal/Linux commands ka pata hona

---

## 5. AWS CLI Install & Configure

### Step 1: AWS CLI Install Karein

```bash
# Packages update karein
sudo apt update

# Zaroori dependencies install karein
sudo apt install unzip curl -y

# AWS CLI v2 download karein
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Zip file extract karein
unzip awscliv2.zip

# Install karein
sudo ./aws/install

# Verify karein ke install ho gaya
aws --version
```

### Step 2: AWS Credentials Nikalein

1. AWS Console mein login karein
2. **IAM > Users** par jaein, apna username click karein
3. **Security credentials** tab open karein
4. **Create access key** par click karein
5. **Access Key ID** aur **Secret Access Key** copy kar lein (yeh dobara nahi milegi, isliye safe jagah save karein)

### Step 3: AWS Configure Karein

```bash
aws configure
```

Yeh terminal aapse yeh puchega:

```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

> ⚠️ **Important:** Access Key aur Secret Key kabhi bhi GitHub par push na karein. Yeh sensitive credentials hain.

---

## 6. Terraform Install

```bash
sudo apt-get update -y
sudo apt-get install -y wget unzip

wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform -version
```

---

## 7. Folder Structure

```
terraform-ec2/
│
├── modules/
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── dev/
    │   ├── provider.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── dev.tfvars
    │
    ├── stg/
    │   ├── provider.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── stg.tfvars
    │
    └── prod/
        ├── provider.tf
        ├── main.tf
        ├── variables.tf
        └── prod.tfvars
```

**Samjhein is structure ko:**
- `modules/ec2/` — Yahan EC2 banane ka reusable code hai (ek hi jagah likha, sab environments use karte hain)
- `environments/dev`, `stg`, `prod` — Har environment apna module call karta hai, apni values ke saath

---

## 8. EC2 Module Explanation

### `modules/ec2/main.tf`

Yeh file 2 cheezein banati hai:

1. **Security Group** — SSH access allow karta hai (port 22 par inbound traffic)
2. **EC2 Instance(s)** — `count` variable ke through multiple instances bhi ban sakte hain

```hcl
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ec2_sg" {
  name        = var.ec2_sg
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  count                  = var.instance_count

  tags = {
    Name        = "${var.tags["Name"]}-${count.index + 1}"
    Environment = "dev"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }
}
```

### `modules/ec2/variables.tf`

Yahan har wo variable define hota hai jo module ko chahiye — instance count, AMI, key name, security group name, ssh port, tags, volume size/type, waghera.

### `modules/ec2/outputs.tf`

Module se kya output milega:

```hcl
output "public_ip" {
  value = aws_instance.ec2[*].public_ip
}

output "public_dns" {
  value = aws_instance.ec2[*].public_dns
}

output "key_pair_used" {
  value = var.key_name
}
```

---

## 9. Environment Setup (Dev/Stg/Prod)

Har environment folder (`dev`, `stg`, `prod`) mein 3 files hoti hain:

1. **`provider.tf`** — AWS region set karta hai:
   ```hcl
   provider "aws" {
     region = "us-east-1"
   }
   ```

2. **`main.tf`** — Key pair banata hai aur EC2 module ko call karta hai:
   ```hcl
   resource "aws_key_pair" "default" {
     key_name   = var.key_name
     public_key = file("~/.ssh/id_rsa.pub")
   }

   module "dev_ec2" {
     source        = "../../modules/ec2"
     environment   = var.environment
     ami           = var.ami
     ec2_username  = var.ec2_username
     key_name      = var.key_name
     ec2_sg        = var.ec2_sg
     ssh_port      = var.ssh_port
     instance_type = var.instance_type
     volume_size   = var.volume_size
     volume_type   = var.volume_type
   }
   ```

3. **`*.tfvars`** — Actual values yahan likhi jati hain (jaise `dev.tfvars`)

### Environment-wise Differences

| Environment | Key Pair Name | Instance Type | SSH CIDR | Owner |
|---|---|---|---|---|
| Dev | terraform-dev-key | t2.micro | 0.0.0.0/0 | DevOps Team |
| Stg | terraform-stg-key | t3.micro | 10.0.0.0/16 | QA Team |
| Prod | terraform-prod-key | t3.medium | 10.0.0.0/16 | ProdOps Team |

> Staging aur Prod banane ke liye simply `dev` folder copy karein aur naam change karein — phir `variables.tf` mein values update kar dein.

---

## 10. Step-by-Step: Kaise Run Karein

Ek naya banda (beginner) yeh steps follow karke poora project chala sakta hai:

### Step 1 — Environment folder mein jaein

```bash
cd environments/dev
```

### Step 2 — Terraform Initialize karein

Yeh command Terraform ko providers download karne aur backend setup karne deti hai.

```bash
terraform init
```

### Step 3 — Plan dekhein

Yeh command batati hai ke Terraform kya kya banane wala hai — bina kuch actually create kiye.

```bash
terraform plan -var-file="dev.tfvars" -out=tfplan
```

### Step 4 — Apply karein

Yeh command actually resources (EC2, security group, key pair) create karti hai.

```bash
terraform apply "tfplan"
```

Ya seedha:

```bash
terraform apply -var-file="dev.tfvars"
```

Terraform confirmation maangega — `yes` type karein.

### Step 5 — Outputs dekhein

```bash
terraform output
```

Yeh aapko instance ka public IP, DNS, key pair name waghera dikhayega.

### Step 6 — Resources delete karein (jab kaam khatam ho jaye)

> ⚠️ Yeh zaroor karein taake AWS bill na aaye jab instance use nahi ho rahe.

```bash
terraform destroy
```

---

## 11. Best Practices

| Category | Recommendation |
|---|---|
| State Management | Remote state use karein (S3 + DynamoDB) taake team collaboration aasan ho |
| Security | SSH ko `0.0.0.0/0` ke bajaye apni public IP tak restrict karein |
| Secrets | Credentials kabhi hardcode na karein — AWS CLI ya environment variables use karein |
| Modules | Har resource ko modular rakhein taake reuse ho sake |
| Tagging | Consistent tags lagayein taake ownership aur cost tracking clear rahe |
| Version Control | Sirf `.tf` files commit karein, `.terraform/` aur `*.tfstate` ko `.gitignore` mein daalein |

---

## 12. Outcomes

- ✅ Dev, Stg aur Prod ke liye alag alag EC2 instances
- ✅ Key pair aur security group automatically setup
- ✅ Clean, modular aur reusable code architecture
- ✅ CI/CD pipelines aur remote state ke saath integrate karne ke liye ready

---


---

## 🙋 Contribution / Questions

Agar koi is project ko samajhne mein stuck ho ya improvement suggest karna chahe, issue open karein ya pull request bhejein.
