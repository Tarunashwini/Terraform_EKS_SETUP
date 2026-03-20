variable "region" {

}

variable "environment" {

}

variable "vpc_cidr" {

}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "desired_size" {

}

variable "max_size" {

}

variable "min_size" {

}

variable "allowed_ssh_cidr" {

}