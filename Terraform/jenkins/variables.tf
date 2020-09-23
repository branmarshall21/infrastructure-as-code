variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "Development"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "instance_ami" {

}
variable "keyname" {
  default = "MyPrivateKey"
}

variable "vpc_name" {
  description = "AWS region to create VPC"
  default     = "jenkins-vpc"
}

variable "vpc_cidr" {
  description = "AWS region to create VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_secondary_cidr" {
  description = "AWS region to create VPC"
  default     = ["10.0.10.0/16"]
}

variable "public_subnets_cidr" {
  description = "AWS region to create VPC"
  default     = ["10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  description = "AWS region to create VPC"
  default     = ["10.0.10.0/24"]
}
