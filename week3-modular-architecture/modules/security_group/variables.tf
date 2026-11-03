variable "name" {
  type        = string
  description = "Security group name."
}

variable "description" {
  type        = string
  description = "Security group description."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID in which to create the security group."
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Restricted source CIDR allowed to connect over SSH."
}
