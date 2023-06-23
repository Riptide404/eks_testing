#terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
  }
}

provider "aws" {
  access_key = var.AccessKey
  secret_key = var.SecretKey
  region = var.region
}

## new vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

## internet gateway for the aws aws
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}

# Create the subnet within the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id  = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2"
  tags = {
    Name = "my-subnet"
  }
}

## security group for eks cluster
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "my-sg"
  }
}

## iam role for eks cluster
resource "aws_iam_role" "my_eks_role" {
  name = "my-eks-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#Policy attachment
resource "aws_iam_role_policy_attachment" "my_eks_admin_policy_attachment" {
  role      = aws_iam_role.my_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSAdminPolicy"
}

#create the actual EKS cluster
resource "aws_eks_cluster" "my_cluster" {
  name = "my-cluster"
  role_arn = aws_iam_role.my_eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.my_subnet.id]
    security_group_ids = [aws_security_group.my_sg.id]
  }
}

#Outputs
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.my_cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = aws_eks_cluster.my_cluster.certificate_authority.0.data
}
