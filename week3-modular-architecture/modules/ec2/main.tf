resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.name}-key"
  }
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y python3
  EOF

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = var.name
    Role = "ansible-managed"
  }
}
