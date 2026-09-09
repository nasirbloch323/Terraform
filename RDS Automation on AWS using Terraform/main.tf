############################################
# Provider Configuration
############################################
provider "aws" {
  region = "us-east-1"   # AWS region jahan resources banenge
}

############################################
# DB Subnet Group
############################################
# RDS ko kis subnet(s) me deploy karna hai, uska group define karta hai
# Multi-AZ ke liye kam se kam 2 different AZs ke subnets chahiye
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "app-rds-subnet-group"
  description = "Subnet group for MySQL RDS instance"
  subnet_ids  = [
    "subnet-005d4953d9734f867",   # AZ-1 ka subnet
    "subnet-0db13bfc832d33ece"    # AZ-2 ka subnet (multi-az ke liye zaroori)
  ]

  tags = {
    Name        = "nasir-rds-subnet-group"
    Environment = "dev"
    Project     = "RDS-Automation"
  }
}

############################################
# Security Group
############################################
# RDS instance ke liye firewall rules define karta hai
resource "aws_security_group" "rds_sg" {
  name        = "app-rds-sg"
  description = "Allow MySQL access from application servers"
  vpc_id     = "vpc-0f9febdaf7058a6a6"   # jis VPC me SG banega

  # Inbound rule: sirf internal network (10.0.0.0/16) se MySQL port (3306) allow
  ingress {
    description = "MySQL access from private network"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule: sab kuch allow (default open egress)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 matlab sare protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-rds-sg"
    Environment = "dev"
    Project     = "RDS-Automation"
  }
}

############################################
# RDS MySQL Instance
############################################
resource "aws_db_instance" "mysql" {
  identifier              = "app-mysql-db"   # RDS instance ka naam
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"    # instance size (small/dev-tier)
  allocated_storage       = 20               # GB me storage
  storage_type            = "gp3"            # general purpose SSD (gp3 = latest gen, cost-efficient)

  db_name                 = "appdb"          # initial database ka naam
  username                = "admin"          # master username
  password                = "StrongPassword123!"  # ⚠️ ISSUE: hardcoded plaintext password (neeche dekhein)

  multi_az                = true             # High availability ke liye standby replica dusre AZ me
  publicly_accessible     = false            # Internet se direct access band (good practice)

  backup_retention_period = 7                # 7 din tak automated backups rakhega
  backup_window           = "03:00-04:00"    # backup lene ka time window (UTC)
  maintenance_window      = "sun:05:00-sun:06:00"  # patching/maintenance window

  skip_final_snapshot     = true             # ⚠️ ISSUE: delete karte waqt final snapshot NAHI banega
  deletion_protection     = false            # ⚠️ ISSUE: accidental delete se protection off hai

  vpc_security_group_ids  = [aws_security_group.rds_sg.id]     # upar wala SG attach
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name  # upar wala subnet group attach

  tags = {
    Name        = "app-mysql-db"
    Environment = "dev"
    Project     = "RDS-Automation"
  }
}