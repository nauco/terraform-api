### VPC ###
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  ### VPC CIDR은 변수로 받는다. ###
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.service}"  ### VPC 이름은 Service 명으로 받는다. ###
  }
}

### Subnet ###
resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, 3)
     ### Subnet CIDR은 16개로 나눠진 VPC CIDR Array의 4번째로 받는다. ###
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "sub-${var.service}-public-a"
  }
}

### Internet Gateway ###
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-${var.service}"
  }
}
resource "aws_eip" "eip" {
  vpc               =   true
  depends_on        =   [aws_internet_gateway.igw]
}

### Route Table ###
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt-${var.service}-public"
  }
}
resource "aws_route_table_association" "publicrtasso-a" {
  subnet_id = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public.id
}

### Default Security Group ###
resource "aws_security_group_rule" "sgrprule-ec2" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "TCP"
  description = "sample web page"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.defaultsgrp.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "defaultsgrp" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

### EC2 ###
resource "aws_instance" "web" {
  ami           = "ami-005e54dee72cc1d00"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    aws_security_group.defaultsgrp.id
  ]
  user_data = <<EOF
sudo su
yum update -y
yum install -y httpd.x86_64
yum install -y jq
REGION_AV_ZONE=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .availabilityZone -r`
systemctl start httpd.service
systemctl enable httpd.service
echo “Hello World from $(hostname -f) from the availability zone: $REGION_AV_ZONE” > /var/www/html/index.html
EOF
  subnet_id = aws_subnet.public-subnet-a.id
  tags = {
    Name = "ec2-${var.service}"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip   ### Apply가 완료되면 EC2의 Public IP를 반환한다.
}
