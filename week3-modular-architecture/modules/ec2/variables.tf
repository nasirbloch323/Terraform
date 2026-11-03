variable "name" {
  type        = string
  description = "EC2 instance and key pair name."
}

variable "ami_id" {
  type        = string
  description = "Ubuntu AMI ID resolved by the root module."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the instance."
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB."
}

variable "ssh_public_key" {
  type        = string
  description = "OpenSSH public key contents."
  sensitive   = true
}
