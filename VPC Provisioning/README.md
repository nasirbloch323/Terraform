# AWS VPC Provisioning with Terraform (Public & Private Subnets, IGW, NAT Gateway, Route Tables)

Ye README is tarah likha gaya hai ke agar aap Terraform ya AWS networking mein bilkul naye (beginner) ho, phir bhi har step samajh aa jaye. Har section mein pehle "kya kar rahe hain" phir "kyun kar rahe hain" explain kiya gaya hai.

---

## 1. Project kis liye hai (Problem Statement)

Jab hum AWS par cloud infrastructure banate hain, to sabse pehle hume ek **network** chahiye hota hai jahan hamare servers, databases waghera reh sakein. Is network ko **VPC (Virtual Private Cloud)** kehte hain.

Manually AWS console mein click-click kar ke VPC, subnets, gateways banana:
- Time waste karta hai
- Ghalti (mistakes) hone ke chances zyada hote hain
- Dusre environment (dev/stage/prod) mein dobara same cheez banani mushkil hoti hai

Isliye hum **Terraform** use karte hain — ye ek **Infrastructure as Code (IaC)** tool hai jisse hum code likh kar infrastructure banate hain, aur wo code baar baar chala kar same setup kahin bhi reproduce kar sakte hain.

---

## 2. Basic Concepts (Beginner ke liye zaroori)

Aage badhne se pehle ye terms samajh lein:

| Term | Aasan Explanation |
|---|---|
| **VPC** | Aapka apna private network AWS ke andar, jaise ek boundary wall |
| **Subnet** | VPC ke andar chhote chhote sections/hisse |
| **Public Subnet** | Wo subnet jiska seedha internet se connection hota hai (jaise website servers) |
| **Private Subnet** | Wo subnet jo internet se seedha connect nahi hota (jaise database — security ke liye) |
| **Internet Gateway (IGW)** | Ye VPC ko internet se connect karta hai — sirf public subnet ke liye |
| **NAT Gateway** | Private subnet ko internet tak "outgoing" access deta hai (jaise updates download karna) lekin bahar se andar koi access nahi kar sakta |
| **Route Table** | Ye batata hai ke traffic kahan jayega — jaise GPS/naksha traffic ke liye |
| **CIDR Block** | IP addresses ki range, jaise `10.0.0.0/16` |
| **Availability Zone (AZ)** | AWS ke alag alag data centers ek region ke andar — multiple AZs use karne se agar ek fail ho to doosra chalta rahe (High Availability) |

---

## 3. Poora Architecture ek nazar mein

```
                [ Internet ]
                     |
             [ Internet Gateway ]
                     |
        ---------------------------------
        |     VPC: 10.0.0.0/16          |
        |                                |
   AZ-1: Public Subnet --- NAT Gateway -- Private Subnet
   AZ-2: Public Subnet --- NAT Gateway -- Private Subnet
   AZ-3: Public Subnet --- NAT Gateway -- Private Subnet
        |                                |
        ---------------------------------
```

- Har **AZ** (availability zone) mein ek public + ek private subnet hai — isse HA (high availability) milti hai.
- Public subnet directly Internet Gateway se juda hota hai.
- Private subnet NAT Gateway ke zariye internet tak "sirf outgoing" access leta hai.
- Route tables decide karti hain ke kis subnet ka traffic kahan route hoga.

---

## 4. Prerequisites (Shuru karne se pehle kya chahiye)

- AWS account jismein EC2, VPC, IAM permissions ho
- AWS CLI installed
- Terraform installed
- Basic terminal/bash ka pata ho

---

## 5. Step 1 — AWS CLI Install aur Configure karna

### 5.1 AWS CLI Install karna (Ubuntu/Debian)

```bash
# System update karo
sudo apt update

# Zaroori tools install karo
sudo apt install unzip curl -y

# AWS CLI v2 download karo
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Zip file ko unzip karo
unzip awscliv2.zip

# Installer run karo
sudo ./aws/install

# Verify karo ke install ho gaya
aws --version
```

**Kyun?** AWS CLI ek command-line tool hai jisse hum apne AWS account se terminal se baat kar sakte hain, aur Terraform isi ke credentials use kar ke AWS par resources banata hai.

### 5.2 AWS Credentials lena

1. AWS Console kholo
2. **IAM > Users >** apna username click karo
3. **Security credentials** tab par jao
4. **Create access key** par click karo
5. **Access Key ID** aur **Secret Access Key** copy kar lo (ye sensitive hai, kisi ko mat batana)

### 5.3 AWS CLI Configure karna

```bash
aws configure
```

Ye aapse ye puchega:

```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Kyun?** Isse aapka computer AWS account se authenticate ho jata hai, taake Terraform aapke account mein resources bana sake.

---

## 6. Step 2 — Terraform Install karna

```bash
# System update
sudo apt-get update -y
sudo apt-get install -y wget unzip

# Terraform download karo
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip

# Unzip karo
unzip terraform_1.5.7_linux_amd64.zip

# System path mein move karo taake terraform command kahin se bhi chale
sudo mv terraform /usr/local/bin/

# Verify karo
terraform -version
```

---

## 7. Step 3 — Project Folder Structure samajhna

Professional Terraform projects mein hum sab kuch ek hi file mein nahi likhte — hum ise **modules** aur **environments** mein tor dete hain, taake code **reusable** aur **maintainable** rahe.

```
terraform-vpc/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
│
├── modules/
│   └── vpc/
│       ├── main.tf         <- VPC ka asal logic yahan hai
│       ├── variables.tf    <- Module ke input variables
│       ├── outputs.tf      <- Module se bahar bhejne wali values
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
│   │   └── (same files)
│   │
│   └── prod/
│       └── (same files)
```

**Is structure ka faida:**
- `modules/vpc` mein sirf ek dafa VPC ka code likha jata hai
- `environments/dev`, `environments/stage`, `environments/prod` sirf us module ko **call** karte hain apni apni values (CIDR, project name) ke saath
- Isse dev, stage, aur prod mein exact same architecture milta hai, bas values alag hoti hain

---

## 8. Step 4 — CIDR aur `cidrsubnet()` function samajhna (bohot zaroori)

Terraform mein hum subnets ko manually har CIDR likhne ke bajaye is formula se auto-generate karte hain:

```hcl
cidrsubnet("10.0.0.0/16", 8, i)
```

### Iska matlab kya hai?

- `prefix = "10.0.0.0/16"` → Yani pehle 16 bits fixed hain (`10.0`), baaki hum use kar sakte hain
- `newbits = 8` → Hum 8 aur bits "borrow" kar rahe hain taake chote subnets banein
- `netnum = i` → Ye batata hai konsa number wala subnet chahiye (0, 1, 2...)

Jab hum `/16` mein `8` bits aur add karte hain to result `/24` ban jata hai. Har `/24` subnet mein **256 IP addresses** hoti hain.

### Table se samjho:

| i (netnum) | Subnet size | Third Octet | Result CIDR |
|---|---|---|---|
| 0 | 256 | 0 | `10.0.0.0/24` |
| 1 | 256 | 1 | `10.0.1.0/24` |
| 2 | 256 | 2 | `10.0.2.0/24` |

Simple formula:
```
third_octet = floor(netnum * subnet_increment / 256)
```

Yani har baar `i` badhne se third octet 1 se badhta jata hai — is tarah Terraform automatically alag alag non-overlapping subnets bana deta hai, hume manually har CIDR type karne ki zaroorat nahi.

---

## 9. Step 5 — VPC Resources ka code samajhna (line by line concept)

Neeche har resource ka kaam bataya gaya hai (poora code humare Terraform files mein hai):

### 9.1 `aws_vpc` — Main Network
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```
Ye hamara main VPC (private network) banata hai, `10.0.0.0/16` range ke saath.

### 9.2 `aws_subnet` (Public)
Public subnet banate waqt `map_public_ip_on_launch = true` set karte hain, taake us subnet mein launch hone wale instances ko automatically ek public IP mile.

### 9.3 `aws_subnet` (Private)
Private subnet mein ye setting nahi hoti — is wajah se is subnet ke resources ko koi public IP nahi milta, aur wo bahar se directly accessible nahi hote.

### 9.4 `aws_internet_gateway`
Ye VPC ko internet se jodta hai. Sirf ek hi IGW poore VPC ke liye kaafi hota hai.

### 9.5 `aws_eip` (Elastic IP)
NAT Gateway ko ek static/fixed public IP chahiye hoti hai hone ke liye — wo isi Elastic IP se milti hai.

### 9.6 `aws_nat_gateway`
Ye ek public subnet ke andar banta hai (kyunke ise khud internet chahiye), aur phir private subnets is se hoke bahar internet tak outgoing traffic bhejte hain.

**Important:** NAT Gateway hamesha **public subnet** mein hota hai, private mein nahi — ye common confusion hai beginners ke liye.

### 9.7 Route Tables
- **Public Route Table:** `0.0.0.0/0` (yani "har jagah ka traffic") ko **Internet Gateway** ki taraf bhejti hai
- **Private Route Table:** `0.0.0.0/0` traffic ko **NAT Gateway** ki taraf bhejti hai

### 9.8 Route Table Associations
Ye batata hai ke konsa subnet konsi route table use karega. Public subnets → Public RT, Private subnets → Private RT.

---

## 10. Step 6 — Reusable Module kaise likhte hain

`modules/vpc/main.tf` mein hum sab kuch **variables** ke through banate hain (hardcoded values ke bajaye), jaise:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr   # Ye value environment se aayegi
  ...
}
```

`modules/vpc/variables.tf` mein hum define karte hain ke module ko kaunse inputs chahiye:

```hcl
variable "project" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {}
variable "private_subnet_cidrs" {}
variable "tags" {}
```

`modules/vpc/outputs.tf` mein hum define karte hain ke module se bahar kya values milengi (jaise VPC ID), taake dusri jagah use ho sakein:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

---

## 11. Step 7 — Environment (Dev) kaise module ko call karta hai

`environments/dev/main.tf`:

```hcl
module "vpc_dev" {
  source              = "../../modules/vpc"
  project             = var.project
  environment         = "dev"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs= var.private_subnet_cidrs
  tags                = var.tags
}
```

Yahan hum sirf `modules/vpc` ko **call** kar rahe hain apni values de kar. Yehi trick hai reusability ki — same module, sirf variables alag.

### Values (Dev/Stage/Prod ke liye alag CIDR):

| Environment | VPC CIDR | Public Subnets | Private Subnets |
|---|---|---|---|
| Dev | `10.0.0.0/16` | `10.0.1.0/24`, `10.0.2.0/24` | `10.0.3.0/24`, `10.0.4.0/24` |
| Stage | `10.1.0.0/16` | `10.1.1.0/24`, `10.1.2.0/24` | `10.1.3.0/24`, `10.1.4.0/24` |
| Prod | `10.2.0.0/16` | `10.2.1.0/24`, `10.2.2.0/24` | `10.2.3.0/24`, `10.2.4.0/24` |

**Kyun alag CIDR?** Taake agar future mein VPCs ko aapas mein connect karna pare (VPC Peering), to IP ranges overlap na karein.

---

## 12. Step 8 — Terraform ko actually chalana (Deployment Steps)

```bash
# 1. Dev environment folder mein jao
cd environments/dev

# 2. Terraform initialize karo (providers/modules download karega)
terraform init

# 3. Plan dekho — ye batayega ke kya kya banega, bina actually banaye
terraform plan -out=tfplan

# 4. Apply karo — ab AWS par actually resources ban jayenge
terraform apply "tfplan"

# 5. Outputs dekho (jaise VPC ID, subnet IDs)
terraform output

# 6. Agar sab kuch delete karna ho
terraform destroy
```

### Har command ka kaam:

| Command | Kya karta hai |
|---|---|
| `terraform init` | Zaroori plugins/providers download karta hai, module load karta hai |
| `terraform plan` | Preview dikhata hai ke kya banega/change hoga — koi resource abhi nahi banta |
| `terraform apply` | Asal mein AWS par resources create karta hai |
| `terraform output` | Module se milne wali values (VPC ID waghera) dikhata hai |
| `terraform destroy` | Saare banaye hue resources delete kar deta hai |

**Tip for beginners:** Hamesha `plan` pehle chalao, `apply` se pehle — isse aap dekh sakte ho ke Terraform kya karne wala hai, koi surprise nahi hoga.

---

## 13. Best Practices (In cheezon ka khayal rakhein)

| Category | Recommendation |
|---|---|
| CIDR Management | Har environment ka CIDR alag rakho, overlap na ho |
| Subnets | Kam az kam 2 public aur 2 private subnets rakho (High Availability ke liye) |
| NAT Gateway | Production mein har AZ ke liye alag NAT Gateway use karo (agar ek AZ fail ho to doosra chale) |
| Tagging | Har resource ko consistent tags do — cost tracking aur organization ke liye |
| Modularity | Networking code ko hamesha alag module mein rakho, reuse karne ke liye |
| State Management | Terraform state file ko remote **S3 backend** mein store karo, local mein mat rakho (team collaboration ke liye zaroori) |

---

## 14. Expected Outcomes (Ye project mukammal hone ke baad kya milega)

1. **Fully Automated VPC** — Public aur private subnets har specified AZ mein automatically ban jayenge
2. **Secure Networking** — Private subnets internet access le sakein (NAT ke through) bina expose hue
3. **Reusable Terraform Modules** — Ye code kisi bhi naye project mein reuse ho sakta hai
4. **High Availability** — Multiple AZs ki wajah se agar ek AZ down ho to system chalta rahega
5. **Consistency** — Dev, Stage, Prod sab mein exact same architecture, sirf values alag
6. **Documentation as Code** — Terraform code khud hi documentation ka kaam bhi karta hai

---

## 15. Conclusion

Is project mein humne sikha ke kaise ek professional, reusable aur secure AWS networking setup Terraform se automate kiya jata hai. Manual console clicking ke bajaye, ab hum sirf code likh kar, kisi bhi environment mein, kabhi bhi, wahi exact infrastructure consistently deploy kar sakte hain — yehi asal **DevOps aur Infrastructure as Code (IaC)** ka maqsad hai.

---

## Quick Reference — Sab commands ek jagah

```bash
# AWS CLI setup
aws configure

# Terraform workflow
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
terraform output
terraform destroy
```
