# Key Pair
output "key_name" {
  value = aws_key_pair.default.key_name
}

# EC2 Instances (multiple ho sakti hain kyunke count use hua hai)
output "public_ip" {
  value = aws_instance.example[*].public_ip
}

output "instance_id" {
  value = aws_instance.example[*].id
}
