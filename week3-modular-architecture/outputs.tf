output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = module.vpc.public_subnet_id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = module.ec2.public_ip
}

output "ansible_inventory_path" {
  description = "Generated Ansible inventory file."
  value       = local_file.ansible_inventory.filename
}

output "ansible_command" {
  description = "Command to configure the instance with Ansible."
  value       = "ansible-playbook -i ansible/inventory.ini ansible/playbook.yml"
}
