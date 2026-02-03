terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}
resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    availability_zone = "${var.aws_region}a"
        cidr_block = "10.0.1.0/24"
    tags = {
      Name = "${var.project_name}-public-subnet"
    }
  }

resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    availability_zone = "${var.aws_region}b"
        cidr_block = "10.0.2.0/24"
    tags = {
      Name = "${var.project_name}-private-subnet"
    }
  }
resource "aws_internet_gateway" "ig_2tier" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
      Name = "${var.project_name}-igw"
    }
  }  
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.ig_2tier.id
    }

    tags = {
      Name = "${var.project_name}-public-route-table"
    }
  }
resource "aws_route_table_association" "public-route-table-association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
  }

resource "aws_security_group" "aws_grocery_sg" {
  name        = "${var.project_name}-security-group"
  description = "Security group for AWS Grocery application"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["93.234.96.7/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-security-group"
  }
}
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_grocery_sg.id]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_instance" "aws_grocery_instance" {
  ami                         = "ami-00329fcfb4c23f789" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  key_name                    = "urholyness"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.aws_grocery_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }  
}
resource "aws_db_instance" "database" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13"
  auto_minor_version_upgrade = true
    instance_class       = "db.t3.micro"
  db_name              = "grocerymate"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name

  tags = {
    Name = "${var.project_name}-rds-instance"
  }
  
}
  