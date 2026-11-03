module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = data.aws_availability_zones.available.names[0]
}

module "security_group" {
  source = "./modules/security_group"

  name              = "${var.project_name}-${var.environment}-sg"
  description       = "Restricted SSH and public HTTP access"
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidr  = var.ssh_allowed_cidr
}

module "ec2" {
  source = "./modules/ec2"

  name             = "${var.project_name}-${var.environment}-server"
  ami_id           = data.aws_ami.ubuntu.id
  instance_type    = var.instance_type
  subnet_id        = module.vpc.public_subnet_id
  security_group_id = module.security_group.security_group_id
  root_volume_size = var.root_volume_size
  ssh_public_key   = var.ssh_public_key
}

# Generate a ready-to-use Ansible inventory after EC2 receives its public IP.
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/ansible/inventory.ini"
  file_permission = "0600"

  content = templatefile("${path.module}/ansible/inventory.ini.tftpl", {
    public_ip        = module.ec2.public_ip
    private_key_path = var.private_key_path
  })
}
