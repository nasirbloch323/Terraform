variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     =("nasir.pub")
}

variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0332d564d76dbd8d6" # Amazon Linux 2
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = "nasir-key"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_cidr" {
  description = "Allowed CIDR block for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "sg_name" {
  default = "allow_ssh"
}

variable "sg_description" {
  default = "Allow SSH inbound traffic"
}

variable "ssh_port" {
  description = "Port to allow SSH"
  type        = number
  default     = 22
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 3
}

variable "ec2_username" {
  description = "Default SSH username for EC2 instance"
  type        = string
  default     = "ec2-user" # change to 'ubuntu' if needed
}

variable "root_volume_size" {
  description = "Size of the EC2 root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the EC2 root volume (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "env" {
  description = "various environment"
  type        = string
  default     = "dev"
}


variable "tags" {
  type = map(string)
  description = "Resource tags"
  default = {
    Name = "EC2_nasir_dynmic"
  }
}

