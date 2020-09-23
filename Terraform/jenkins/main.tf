provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  # profile                 = "development"
}
#############################################################

    #  Data to get AMI, AZs, etc

#############################################################
data "aws_availability_zones" "available" {}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}
#############################################################

    #  vpc module

#############################################################
resource "aws_vpc" "infrastructure-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "infrastructure"
  }
}
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.infrastructure-vpc.id
  cidr_block = var.vpc_secondary_cidr
}

#############################################################

    #  Subnets resource

#############################################################
resource "aws_subnet" "public-subnet" {
  cidr_block        = var.public_subnets_cidr
  vpc_id            = aws_vpc.infrastructure-vpc.id
  availability_zone = "${var.region}a"
    tags = {
        Name = "Public Subnet"
    }
  }

resource "aws_subnet" "private-subnet" {
  cidr_block        = var.private_subnets_cidr
  vpc_id            = aws_vpc.infrastructure-vpc.id
  availability_zone = "${var.region}a"
  tags = {
      Name = "Private Subnet"
  }
}
#############################################################

    #  Public/Private Route table resource

#############################################################
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.infrastructure-vpc.id
  tags = {
    Name = "jenkins-Public-RouteTable"
  }
}
resource "aws_route_table_association" "public-route-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet.id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.infrastructure-vpc.id
  tags = {
    Name = "jenkins-Private-RouteTable"
  }
}
resource "aws_route_table_association" "private-route-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet.id
}

#############################################################

    #  SG  resource

#############################################################
resource "aws_security_group" "sg_allow_ssh_jenkins" {
  name        = "allow_ssh_jenkins"
  description = "Allow SSH and Jenkins inbound traffic"
  vpc_id      = aws_vpc.infrastructure-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#############################################################

    #  Elastic IP

#############################################################
resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.1.59.0"
  tags = {
    Name = "jenkins-EIP"
  }
}

#############################################################

    #  NAT gateway  resource

#############################################################
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public-subnet.id
  tags = {
      Name = "jenkins-NATGW"
  }
    depends_on = [aws_eip.elastic-ip-for-nat-gw]
}
#############################################################

    #  Route table  resource

#############################################################
  resource "aws_route" "nat-gw-route" {
    route_table_id         = aws_route_table.private-route-table.id
    nat_gateway_id         = aws_nat_gateway.nat-gw.id
    destination_cidr_block = "0.0.0.0/0"
  }
  #############################################################

      #  Internet Gateway  resource

  #############################################################
  resource "aws_internet_gateway" "development-igw" {
    vpc_id = aws_vpc.infrastructure-vpc.id
    tags = {
      Name = "Jenkins-IGW"
    }
  }
  #############################################################

      #  Route table  resource

  #############################################################
  resource "aws_route" "public-internet-igw-route" {
    route_table_id         = aws_route_table.public-route-table.id
    gateway_id             = aws_internet_gateway.development-igw.id
    destination_cidr_block = "0.0.0.0/0"
  }

#############################################################

    #  EC2  resource

#############################################################
resource "aws_instance" "jenkins-instance" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.micro"
  key_name        = var.keyname
  vpc_security_group_ids = [aws_security_group.sg_allow_ssh_jenkins.id]
  subnet_id          = aws_subnet.public-subnet.id
  user_data = file("install-jenkins.sh")

  associate_public_ip_address = true
  tags = {
    Name = "Jenkins-Instance"
  }
}
