provider "aws" {
  region = "ap-northeast-2" # 사용중인 aws region
}

resource "aws_s3_bucket" "test" {
  bucket = var.name
}

variable "name" {
 type = string 
}
