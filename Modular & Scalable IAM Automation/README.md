

## 📋 Table of Contents
1. [Introduction & Problem Statement](#-introduction--problem-statement)
2. [Key Concepts Explained (Asaan Lafzon Mein)](#-key-concepts-explained-asaan-lafzon-mein)
3. [Architecture & Component Summary](#-architecture--component-summary)
4. [Prerequisites](#-prerequisites)
5. [Step 1: AWS CLI Setup & Configuration](#step-1-aws-cli-setup--configuration)
6. [Step 2: Terraform Installation (Ubuntu/Debian)](#step-2-terraform-installation-ubuntudebian)
7. [Project Directory Structure](#-project-directory-structure)
8. [Terraform Code Files & Line-by-Line Explanation](#-terraform-code-files--line-by-line-explanation)
   - [A. `provider.tf`](#a-providertf)
   - [B. `variables.tf`](#b-variablestf)
   - [C. `main.tf` (IAM Resources & Least-Privilege Policy)](#c-maintf-iam-resources--least-privilege-policy)
   - [D. `outputs.tf`](#d-outputstf)
9. [Step-by-Step Execution Workflow](#-step-by-step-execution-workflow)
10. [Verification & Verification Commands](#-verification--verification-commands)
11. [Cleanup / Resource Destruction](#-cleanup--resource-destruction)
12. [Best Practices & Key Takeaways](#-best-practices--key-takeaways)

---

## 🚨 Introduction & Problem Statement

### ❌ Masla Kya Hai? (The Problem)
AWS Console par ja kar manually Users, Groups, Roles aur Policies banana risky aur time-consuming hai:
* **Human Errors:** Galat policy assign hone se security vulnerabilities paida ho sakti hain.
* **Over-Privileged Access:** Users ko zarurat se ziada permissions mil jati hain (Full Admin access).
* **No Auditing / Version Control:** Pata nahi chalta kisne kab aur kya change kiya.
* **Hard to Scale:** Jab 50 developers ya multiple servers hon, to manual setup mushkil ho jata hai.

### ✅ Hal Kya Hai? (The Solution)
**Terraform** ke zariye IAM ko code (Infrastructure as Code) ke taur par manage karna. Is se:
* Har cheez automated, secure aur version-controlled rehti hai.
* **Least Privilege Principle** enforce hota hai (sirf utni permissions jitni zarurat ho).
* Ek single command se pura security setup minutes mein create ya destroy ho jata hai.

---

## 💡 Key Concepts Explained (Asaan Lafzon Mein)

Agar aap bilkul naye hain, to in 5 cheezon ko samajhna zaroori hai:

| Component | Simple Explanation (Urdu / English) | Example |
| :--- | :--- | :--- |
| **IAM User** | Kisi insaan ya developer ka login account (Username + Credentials). | `devops-user` |
| **IAM Group** | Users ka majmooa (Group). Is par permissions lagayi jati hain jo sab members par apply hoti hain. | `DevOpsGroup` |
| **IAM Policy** | Rules ka document jo batata hai ke kya ALLOW hai aur kya DENY. | S3 Read-Only Policy |
| **IAM Role** | AWS Services (jaise EC2) ko di jaane wali **temporary identity/permissions**. | `EC2Role_Nasir` |
| **Instance Profile** | **EC2 aur Role ke darmyan ka Passport/Bridge**. Iske baghair EC2 Role ko use nahi kar sakta. | `EC2InstanceProfile` |

---

## 🏗 Architecture & Component Summary

Is project mein hum automated tareeqe se neeche diye gaye resources create kar rahe hain:


```

[ IAM User ] ──► (Added to) ──► [ IAM Group ] ──► (Attached with) ──► [ Custom IAM Policy ]
│
[ EC2 Server ] ──► [ Instance Profile ] ──► [ IAM Role ] ────────────────────┘

```

---

## 🛠 Prerequisites

Pehle se tayar rakhein:
1. Active **AWS Account**.
2. Linux Server (Ubuntu/Debian) ya GitHub Codespaces.
3. Administrative access terminal par.

---

## ⚙️ Step 1: AWS CLI Setup & Configuration

AWS CLI ke zariye Terraform aapke AWS account se communicate karta hai.

### Single-Line Commands for Installation:

```bash
# Line 1: Package list update karein
sudo apt update -y

# Line 2: Zaruri tools install karein (curl aur unzip)
sudo apt install unzip curl -y

# Line 3: AWS CLI v2 ki installation file download karein
curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"

# Line 4: Zip file ko extract (unzip) karein
unzip awscliv2.zip

# Line 5: Installer script run karein
sudo ./aws/install

# Line 6: Verify karein ke AWS CLI sahi install hua hai ya nahi
aws --version

```

### AWS Credentials Configure Karein:

AWS Console > **IAM** > **Users** > **Security Credentials** > **Create Access Key** par ja kar keys generate karein.

Terminal par yeh command chalayein:

```bash
aws configure

```

Aap se neeche di gayi 4 details maangi jayengi:

* **AWS Access Key ID:** `AKIAXXXXXXXXXXXXXXXX`
* **AWS Secret Access Key:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYZEXAMPLEKEY`
* **Default region name:** `us-east-1`
* **Default output format:** `json`

---

## 📦 Step 2: Terraform Installation (Ubuntu/Debian)

Agar Terraform pehle se install nahi hai, to in commands ko ek ek karke chalayein:

```bash
# Line 1: Package updates
sudo apt-get update -y

# Line 2: Wget aur Unzip install karein
sudo apt-get install -y wget unzip

# Line 3: Terraform v1.5.7 binary download karein
wget [https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip](https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip)

# Line 4: Downloaded zip ko extract karein
unzip terraform_1.5.7_linux_amd64.zip

# Line 5: Binary ko system PATH mein move karein taake har jagah se run ho sake
sudo mv terraform /usr/local/bin/

# Line 6: Version check karke confirm karein
terraform -version

```

---

## 📂 Project Directory Structure

Apne project folder ke andar yeh 4 files banayein:

```text
terraform-iam/
├── provider.tf      # AWS Provider configuration
├── variables.tf     # Customizable input variables
├── main.tf          # Core IAM resources & custom security policies
└── outputs.tf       # Sensitive outputs (Access Keys & Role Names)

```

---

## 📝 Terraform Code Files & Line-by-Line Explanation

### A. `provider.tf`

Yeh file Terraform ko batati hai ke kis cloud provider (AWS) aur kis region ke saath connect hona hai.

```hcl
# Line 1: AWS Provider block define kar rahe hain
provider "aws" {
  # Line 2: Target AWS Region jahan resources banengi
  region = "us-east-1"
}

```

---

### B. `variables.tf`

Variables use karne se code flexible banta hai. Hum yahan default values set kar rahe hain.

```hcl
# Line 1: IAM User name ke liye variable
variable "iam_user_name" {
  type    = string
  default = "devops-user"
}

# Line 2: IAM Group name ke liye variable
variable "iam_group_name" {
  type    = string
  default = "DevOpsGroup"
}

# Line 3: Default managed policies ki list
variable "iam_policies" {
  type    = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

```

---

### C. `main.tf` (IAM Resources & Least-Privilege Policy)

Yeh aapki **main configuration file** hai. Is mein hum Group, User, Role, Custom Policy, aur Instance Profile create kar rahe hain.

```hcl
# ==========================================
# 1. IAM GROUP & USER CREATION
# ==========================================

# Line 1: AWS IAM Group create karne ka block
resource "aws_iam_group" "group" {
  name = var.iam_group_name
}

# Line 2: IAM User create karne ka block
resource "aws_iam_user" "user" {
  name = var.iam_user_name
}

# Line 3: User ko Group mein add karne ka membership block
resource "aws_iam_user_group_membership" "membership" {
  user   = aws_iam_user.user.name
  groups = [aws_iam_group.group.name]
}

# Line 4: User ke liye Programmatic Access Keys generate karna
resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

# ==========================================
# 2. IAM ROLE FOR EC2 INSTANCE
# ==========================================

# Line 5: EC2 ke liye IAM Role create karna
resource "aws_iam_role" "ec2_role_nasir" {
  name = "EC2Role_Nasir"

  # Line 6: Assume Role Policy (Sirf EC2 Service is role ko assume kar sakti hai)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# ==========================================
# 3. LEAST-PRIVILEGE CUSTOM POLICY
# ==========================================

# Line 7: Custom Least-Privilege Policy banana (Sirf zaroori permissions)
resource "aws_iam_policy" "ec2_custom_policy" {
  name        = "EC2CustomPolicy"
  description = "Least-privilege policy for EC2 instance control and logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # EC2 Read & Lifecycle actions
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      },
      {
        # EBS Volume operations
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Resource = "*"
      },
      {
        # CloudWatch Logging permissions
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# 4. POLICY ATTACHMENT & INSTANCE PROFILE
# ==========================================

# Line 8: Custom policy ko EC2 Role ke sath attach karna
resource "aws_iam_role_policy_attachment" "ec2_custom_role_attachment" {
  role       = aws_iam_role.ec2_role_nasir.name
  policy_arn = aws_iam_policy.ec2_custom_policy.arn
}

# Line 9: Instance Profile create karna (EC2 ke sath attach karne ke liye)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role_nasir.name
}

```

---

### D. `outputs.tf`

Created resources ki details Terminal par dekhne ke liye:

```hcl
# Line 1: Created IAM Username display karein
output "iam_user_name" {
  value = aws_iam_user.user.name
}

# Line 2: Access Key ID (Sensitive Data)
output "access_key_id" {
  value     = aws_iam_access_key.access_key.id
  sensitive = true
}

# Line 3: Secret Access Key (Sensitive Data)
output "secret_access_key" {
  value     = aws_iam_access_key.access_key.secret
  sensitive = true
}

# Line 4: Instance Profile Name display karein
output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

```

---

## 🚀 Step-by-Step Execution Workflow

In commands ko sequence wise apne terminal par chalayein:

### Step 1: Initialize Working Directory

Terraform plugins aur AWS provider modules download honge.

```bash
terraform init

```

### Step 2: Execution Plan Check Karein

Yeh command batayegi ke AWS par kon kon se resources create honge (Preview mode).

```bash
terraform plan

```

### Step 3: Infrastructure Apply Karein

AWS par actual resources create karne ke liye. Prompt aane par `yes` type karein.

```bash
terraform apply

```

### Step 4: Sensitive Outputs Dekhein

Chunki Access keys sensitive hoti hain, unko dekhne ke liye specific output commands chalayein:

```bash
# Access Key ID dekhne ke liye:
terraform output access_key_id

# Secret Access Key dekhne ke liye:
terraform output secret_access_key

```

---

## 🔍 Verification & Verification Commands

Resources create hone ke baad AWS CLI ke zariye verify karein:

```bash
# 1. IAM User Verify karein
aws iam get-user --user-name devops-user

# 2. IAM Group Verify karein
aws iam get-group --group-name DevOpsGroup

# 3. IAM Role & Instance Profile Verify karein
aws iam get-role --role-name EC2Role_Nasir
aws iam get-instance-profile --instance-profile-name EC2InstanceProfile

```

---

## 🧹 Cleanup / Resource Destruction

Jab aapka practice/testing poora ho jaye, to AWS charges se bachne ke liye tamaam resources ko destroy kar dein:

```bash
terraform destroy

```

Prompt aane par `yes` enter karein. Ek hi command se saaray IAM Users, Roles, aur Policies delete ho jayengi.

---

## 🎯 Best Practices & Key Takeaways

1. **Never Hardcode Credentials:** AWS Access keys ko kabhi bhi `.tf` files ya Git repository mein na likhein. `aws configure` ya environment variables use karein.
2. **Follow Least Privilege:** Users aur Roles ko sirf utni permissions dein jitni unke kaam ke liye zaroori hon (jaise humne `EC2CustomPolicy` mein diya).
3. **Use Instance Profiles for EC2:** Servers par AWS Access Keys store karne ki bajaye Instance Profile / Roles attach karein.
4. **Version Control:** Apni `.tf` files ko GitHub par version control karein taake audit trail maintain rahe.

---

### 👨‍💻 Author & Maintenance

* **Project Name:** Modular & Scalable IAM Automation on AWS
* **Tools Used:** Terraform, AWS IAM, AWS CLI, Linux Bash
* **License:** MIT License

```

```