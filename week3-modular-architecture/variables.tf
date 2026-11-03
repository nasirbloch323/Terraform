variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string
  default     = "week3-platform"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project_name))
    error_message = "project_name must be 3-20 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a valid AWS region, for example us-east-2."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet."
  type        = string
  default     = "10.30.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance size for this learning environment."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Choose an allowed instance type: t2.micro, t2.small, t2.medium, t3.micro, t3.small, or t3.medium."
  }
}

variable "root_volume_size" {
  description = "Encrypted gp3 root volume size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "root_volume_size must be between 8 and 100 GiB."
  }
}

variable "ssh_allowed_cidr" {
  description = "Your public IP in CIDR notation, for example 203.0.113.10/32. Do not use 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0)) && var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "Provide a valid, restricted IPv4 CIDR for SSH; 0.0.0.0/0 is not allowed."
  }
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key used to access the EC2 instance."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", var.ssh_public_key))
    error_message = "ssh_public_key must contain a valid OpenSSH public key."
  }
}

variable "private_key_path" {
  description = "Local path to the matching SSH private key, used by Ansible."
  type        = string
  default     = "~/.ssh/id_ed25519"

  validation {
    condition     = length(trimspace(var.private_key_path)) > 0
    error_message = "private_key_path cannot be empty."
  }
}
