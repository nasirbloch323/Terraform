# Create IAM Group
resource "aws_iam_group" "group" {
  name = var.iam_group_name
}

# Attach policies to the group
resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each   = toset(var.iam_policies)
  group      = aws_iam_group.group.name
  policy_arn = each.value
}

# Create IAM User
resource "aws_iam_user" "user" {
  name = var.iam_user_name
}

# Add user to group
resource "aws_iam_user_group_membership" "membership" {
  user   = aws_iam_user.user.name
  groups = [aws_iam_group.group.name]
}

# Optional: Create access key for IAM user
resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

# Create IAM Role for EC2
resource "aws_iam_role" "ec2_role_nasir" {
  name = "EC2Role_nasir"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach same policies from group to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_role_policies" {
  for_each   = toset(var.iam_policies)
  role       = aws_iam_role.ec2_role_nasir.name
  policy_arn = each.value
}

# Create instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile_nasir"
  role = aws_iam_role.ec2_role_nasir.name
}