# 🗄️ Secure & Scalable DynamoDB Automation on AWS using Terraform

Ye project AWS **DynamoDB** tables ko **Terraform** ke through automatically banata hai — bilkul secure, consistent aur scalable tareeqe se, bina manually AWS Console pe click-click kiye.

---

## 🚩 Problem (Masla kya hai?)

Jab log AWS Console se manually DynamoDB table banate hain, to ye cheezein ghalat ho sakti hain:

- Har environment (dev, staging, prod) mein alag-alag settings ho jati hain
- Capacity settings ghalat set ho jati hain → cost zyada ya performance kharab
- Indexes missing ya galat ban jate hain
- Encryption, backup jese security features bhool jate hain
- Kis ne kya change kiya — track karna mushkil ho jata hai

Yani manual kaam = zyada risk, zyada mehnat, kam control.

## ✅ Solution (Hal kya hai?)

**Terraform** se DynamoDB table ka poora structure code mein likh dete hain (Infrastructure as Code). Phir jitni marzi baar chalao, hamesha wahi sahi, secure aur consistent table banega — har environment mein.

Is project se milta hai:
- Secure tables (encryption on)
- Sab environments mein same configuration
- Growth ke sath scale hone wali database
- Version-controlled code (Git se track hota hai — kis ne kab kya badla)
- Manual ghalti ka chance khatam

---

## 👨‍💻 Ye kis ke liye hai?

DevOps ya Cloud Engineers jo:
- Terraform se DynamoDB table banana chahte hain
- Partition key, sort key define karna chahte hain
- On-demand ya fixed capacity billing set karna chahte hain
- Encryption, backup, indexes by default chahte hain

---

## 📦 Example Scenario (Asaan misaal)

Socho ek app hai jo **orders** store karti hai. Hume ek table chahiye jisme:

- `user_id` → kis user ka order hai
- `order_id` → konsa order hai
- Automatic scaling (on-demand billing)
- Encryption + backup (point-in-time recovery)
- Ek extra index jisse hum order **status** (jese SHIPPED, PENDING) se search kar sakein

Terraform ye sab **dev, staging aur prod** — teeno jagah bilkul same tareeqe se bana deta hai.

---

## 🧠 DynamoDB ke Concepts — Simple Zaban Mein

### 1️⃣ Partition Key (`hash_key`) & Sort Key (`range_key`)

Socho DynamoDB ek bara **cupboard** hai jisme bohat saari **drawers** (partitions) hain.

| Terraform naam | DynamoDB naam | Matlab | Kaam |
|---|---|---|---|
| `hash_key` | Partition Key | Konsi drawer mein data jayega | WHO / WHERE decide karta hai |
| `range_key` | Sort Key | Us drawer ke andar order | WHICH / WHEN decide karta hai |

**Misaal:**

| user_id | order_id |
|---|---|
| U1 | O101 |
| U1 | O102 |
| U2 | O201 |

- U1 ke saare orders **ek hi drawer** (partition) mein hain
- U2 ka data **alag drawer** mein hai

✅ Isse reads/writes bohat fast hote hain kyunke data sab servers pe barabar phel jata hai.

> 🧠 Yaad rakhne ka tareeqa: **Partition Key = kaunsi drawer**, **Sort Key = drawer ke andar tarteeb**

---

### 2️⃣ Global Secondary Index (GSI)

Ye ek **dusra tareeqa hai wahi data dhoondne ka**, lekin alag field se.

- Main table → `user_id` se search hota hai
- GSI → `order_status` se search hota hai (jese sab "SHIPPED" orders dhoondna, bina user_id jaane)

```hcl
global_secondary_index {
  name             = "OrderStatusIndex"
  hash_key         = "order_status"
  projection_type  = "ALL"
}
```

📌 Kab use karein: Reports, admin dashboards, filters (status, category, region)

---

### 3️⃣ Point-in-Time Recovery (PITR)

Ye DynamoDB ka **"Undo Button"** hai — ek time machine!

```hcl
point_in_time_recovery {
  enabled = true
}
```

Agar 10:30 AM ko galti se data delete ho gaya, to aap table ko **10:29 AM** wapas restore kar sakte hain. Pichle **35 din** tak ka data recover ho sakta hai.

---

### 4️⃣ TTL (Time To Live)

Ye purana data **khud-ba-khud delete** kar deta hai.

```hcl
ttl {
  attribute_name = "ttl"
  enabled        = true
}
```

Aap item mein ek Unix timestamp save karte ho:

```json
{
  "user_id": "U1",
  "order_id": "O101",
  "ttl": 1735689600
}
```

Jab current time us timestamp se aage nikal jaye, DynamoDB automatically wo item delete kar deta hai. Free hai, lekin turant nahi hota — background mein hota hai.

**Real-life uses:** Session expiry, OTP expiry, temporary orders, logs cleanup

---

## 📁 Project Structure

```
terraform-dynamodb/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
│
├── modules/
│   └── dynamodb/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │
│   ├── stage/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
```

---

## 🛠️ Prerequisites

- AWS account (EC2, S3, IAM permissions ke sath)
- AWS CLI installed & configured
- Terraform installed

### Step 1: AWS CLI Install Karna

```bash
sudo apt update
sudo apt install unzip curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Step 2: AWS Credentials Lena

1. AWS Console → **IAM > Users** → apna username kholo
2. **Security credentials** tab
3. **Create access key** pe click karo
4. **Access Key ID** aur **Secret Access Key** copy kar lo

### Step 3: AWS Configure Karna

```bash
aws configure
```

```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 4: Terraform Install Karna

```bash
sudo apt-get update -y
sudo apt-get install -y wget unzip
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -version
```

---

## 📥 Clone the Repository

```bash
git clone https://github.com/Umair1061/terraform-dynamodb
```

---

## 🚀 Terraform Workflow (Kaise chalayein)

```bash
# 1. Initialize
terraform init

# 2. Plan (preview karo kya banega)
terraform plan

# 3. Apply (asal mein resources banao)
terraform apply

# 4. Outputs dekho
terraform output

# 5. (Optional) Sab kuch mita do
terraform destroy
```

---

## 🎯 Expected Outcomes

- DynamoDB tables khud-ba-khud, poori tarah automated ban jati hain
- Har environment mein same configuration
- Encryption + point-in-time recovery ke sath secure tables
- Indexes ki wajah se app performance behtar
- Manual ghalti ka risk kam
- Sab kuch Git mein track ho, easily audit/rollback ho sake

---

## 📝 Conclusion

Terraform se DynamoDB ko automate karna ek **secure, scalable aur repeatable** tareeqa hai AWS pe NoSQL database manage karne ka. Isse:

- Tables hamesha consistent aur replicate karne mein aasan hote hain
- Security best practices (encryption, backup) automatically enforce hoti hain
- Har change track aur reverse ho sakta hai
- DevOps teams bina manual overhead ke confidently scale kar sakti hain

Ye approach modern cloud environments mein reliable, cost-effective aur production-ready DynamoDB deployments ki strong foundation banati hai.