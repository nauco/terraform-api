provider "aws" {
    region = "ap-northeast-2"
}

variable "vpc_cidr" {

}

variable "service" {
  type = string
}

