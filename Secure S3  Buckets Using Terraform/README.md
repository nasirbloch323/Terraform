# 🔐 Secure S3 Buckets Using Terraform

Provision a **production-ready, secure Amazon S3 bucket** using Terraform — with versioning, server-side encryption, and full public access blocking configured out of the box.

This project follows AWS security best practices to ensure your S3 bucket is **never publicly exposed by default** and all data is **encrypted at rest**.

---

## 📋 Features

- ✅ **S3 Bucket Provisioning** – Creates a uniquely named, tagged S3 bucket
- ✅ **Versioning Enabled** – Protects against accidental deletes/overwrites
- ✅ **Server-Side Encryption (AES256)** – Data encrypted at rest by default
- ✅ **Public Access Blocked** – All four public access block settings enabled
- ✅ **Resource Tagging** – Consistent tags for cost tracking and ownership
- ✅ **Terraform Outputs** – Bucket name and ARN exposed for downstream use

---

## 🏗️ Architecture

```
provider (aws)
   │
   └── aws_s3_bucket.mybucket
          ├── aws_s3_bucket_versioning
          ├── aws_s3_bucket_server_side_encryption_configuration
          └── aws_s3_bucket_public_access_block
```

---

## 📦 Prerequisites

Before you begin, make sure you have:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3`
- An [AWS Account](https://aws.amazon.com/)
- AWS CLI configured with valid credentials:
  ```bash
  aws configure
  ```

---

## 🚀 Usage

Clone the repository and navigate into the project folder:

```bash
git clone <your-repo-url>
cd secure-s3-buckets-terraform
```

Initialize Terraform (downloads the AWS provider):

```bash
terraform init
```

Validate and preview the changes:

```bash
terraform fmt
terraform validate
terraform plan
```

Apply the configuration to create the resources:

```bash
terraform apply
```

Destroy resources when no longer needed:

```bash
terraform destroy
```

---

## ⚙️ Configuration

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Creates the base S3 bucket with tags |
| `aws_s3_bucket_versioning` | Enables object versioning |
| `aws_s3_bucket_server_side_encryption_configuration` | Enforces AES256 encryption at rest |
| `aws_s3_bucket_public_access_block` | Blocks all public ACLs and policies |

### Variables to customize

Update the following in `main.tf` before deploying:

```hcl
bucket = "your-unique-bucket-name" # must be globally unique, lowercase, hyphen-separated
```

> ⚠️ S3 bucket names must be globally unique across **all** AWS accounts and can only contain lowercase letters, numbers, and hyphens.

---

## 📤 Outputs

| Output | Description |
|---|---|
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the created S3 bucket |

---

## 🛡️ Security Notes

This configuration blocks **all** public access by default and encrypts data at rest. For production workloads, consider extending this project with:

- Bucket policies restricting access to specific IAM roles
- Logging via `aws_s3_bucket_logging`
- Lifecycle rules for cost optimization
- KMS-based encryption instead of AES256 for stricter key control

---

## 🗂️ Project Structure

```
.
├── main.tf          # Provider, resources, and outputs
└── README.md         # Project documentation
```

---

## 🧑‍💻 Author

**Nasir** — DevOps Engineer  
Building secure, automated cloud infrastructure with Terraform & AWS.

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
