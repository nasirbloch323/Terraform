variable "iam_user_name" {
  default = "nasir-user"
}

variable "iam_group_name" {
  default = "DevOpsGroup"
}

variable "iam_policies" {
  type    = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
