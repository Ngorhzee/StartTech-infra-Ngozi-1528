variable "vpc_id" {
    type = string
}
variable "public_subnets" {
    type = list(string)
}
variable "private_subnets" {
    type = list(string)
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}
