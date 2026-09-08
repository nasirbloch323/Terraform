# AWS provider define kar rahe hain — Terraform ko batana ke kis cloud pe kaam karna hai
provider "aws" {
  region = "us-east-1"   # AWS region select kiya — us-east-1 (N. Virginia) mein resources banenge
}

# DynamoDB table resource — "orders" naam se Terraform ke andar iska reference banega
resource "aws_dynamodb_table" "orders" {
  name         = "orders-table"       # Table ka asal naam jo AWS console mein dikhega
  billing_mode = "PAY_PER_REQUEST"    # On-demand billing — jitna use hoga utna pay karo, fix capacity set nahi karni

  hash_key  = "user_id"    # Partition Key — decide karta hai data KIS drawer/partition mein jayega
  range_key = "order_id"   # Sort Key — usi partition ke andar data ko TARTEEB (order) mein rakhta hai

  # Ab har attribute (column) ka naam aur type define kar rahe hain
  # Ye sirf un attributes ke liye zaroori hai jo key (hash/range) ya index mein use ho rahe hain

  attribute {
    name = "user_id"   # Attribute ka naam — partition key ke liye
    type = "S"         # "S" = String type
  }

  attribute {
    name = "order_id"  # Attribute ka naam — sort key ke liye
    type = "S"         # "S" = String type
  }

  attribute {
    name = "order_status"  # Attribute ka naam — GSI (index) ke liye chahiye
    type = "S"              # "S" = String type
  }

  #attribute {
    #name = "ttl"   # Attribute ka naam — TTL (auto-delete) feature ke liye chahiye
   # type = "N"     # "N" = Number type (Unix timestamp store hoga)
 # }

  # Global Secondary Index — table ko ek ALTERNATE tareeqe se search karne deta hai
  global_secondary_index {
    name            = "OrderStatusIndex"   # Index ka naam — isi naam se query karenge
    hash_key        = "order_status"       # Is index ki apni partition key — order_status se search
    projection_type = "ALL"                # "ALL" matlab index mein table ke SAARE columns copy hongay
  }

  # Point-in-Time Recovery — DynamoDB ka "undo button" / time machine
  point_in_time_recovery {
    enabled = true   # True karne se pichle 35 din tak ka data restore ho sakta hai
  }

  # TTL (Time To Live) — purana data khud-ba-khud delete karne ke liye
  ttl {
    attribute_name = "ttl"   # Konsa attribute TTL timestamp store karega
    enabled        = true    # TTL feature ON kar diya
  }

  # Server-side encryption — data ko disk pe encrypted state mein store karta hai
  server_side_encryption {
    enabled = true   # Encryption ON — security best practice
  }

  # Tags — resource ko identify/organize karne ke liye metadata
  tags = {
    Environment = "dev"                    # Ye batata hai ye table kis environment ki hai
    Project     = "DynamoDB-Automation"    # Project ka naam — billing/reporting mein help karta hai
  }
}