provider "aws" {
  region = var.region
}

# VPC Creation
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "devops-vpc"
  }
}

# Subnet Creation
resource "aws_subnet" "devops_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "devops-subnet"
  }
}

# Security Group Creation
resource "aws_security_group" "devops_sg" {
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # for SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For Cockpit
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins
  }


  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # For Datadog
  }


  ingress {
    from_port   = 8125
    to_port     = 8125
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # For Datadog
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # allow internet traffic
  }


  tags = {
    Name = "devops-sg"
  }
}

# Key Pair for SSH Access
resource "aws_key_pair" "devops_key" {
  key_name   = "devops_key"
  public_key = file("~/.ssh/devops_key.pem.pub")
}


# Internet Gateway
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "devops-igw"
  }
}


# Route Table
resource "aws_route_table" "devops_route_table" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "devops-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "devops_subnet_association" {
  subnet_id      = aws_subnet.devops_subnet.id
  route_table_id = aws_route_table.devops_route_table.id
}



# Define roles and scripts in locals
locals {
  roles = ["jenkins", "sonarqube", "tomcat"]
}

# VPC, Subnet, Security Group, and Key Pair definitions remain unchanged...

# EC2 Instance Creation
resource "aws_instance" "devops_instance" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.devops_subnet.id
  security_groups = [
    aws_security_group.devops_sg.id
  ]
  key_name = aws_key_pair.devops_key.key_name

  # Pass instance-specific user_data
  user_data = templatefile("${path.module}/scripts/${local.roles[count.index]}.sh", {
    datadog_api_key = var.datadog_api_key
  })

  tags = {
    Name = local.roles[count.index]
    Role = local.roles[count.index]
  }
}

