variable "aws_region" {

  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "starttech"
}

variable "mongo_uri" {
  type    = string
}

variable "db_name" {
  type    = string
  
}

variable "jwt_secret" {
  type    = string
  
}