variable "project_name" {
  type        = string
  description = "Project identifier."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR."
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet IPv4 CIDR."
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the public subnet."
}
