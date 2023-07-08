# #terraform providers
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.4"
#     }
#   }
#   kubernetes = {
#     source = "hashicorp/kubernetes"
#     version = "~> 2.15.0"
#   }
# }
#
# provider "aws" {
#   region = var.region
# }
#
# provider "kubernetes" {
#   host            = module.eks.cluster.endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }
#
# ## variables
#
# variable "region" {
#     type = string
#     default = "us-east-1"
# }
#
# variable "cluster_name" {
#     description = "EKS cluster name"
#     type = string
# }
#
# #maybe the roles to be assuming
# ## new vpc
# resource "aws_vpc" "my_vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "my-vpc"
#   }
# }
#
# ## internet gateway for the aws aws
# resource "aws_internet_gateway" "my_igw" {
#   vpc_id = aws_vpc.my_vpc.id
#   tags = {
#     Name = "my-igw"
#   }
# }
#
# # Create the subnet within the VPC
# resource "aws_subnet" "my_subnet" {
#   vpc_id  = aws_vpc.my_vpc.id
#   cidr_block = "10.0.0.0/24"
#   availability_zone = "us-east-1b"
#   tags = {
#     Name = "my-subnet"
#   }
# }
#
# resource "aws_subnet" "my_other_subnet" {
#   vpc_id  = aws_vpc.my_vpc.id
#   cidr_block = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
#   tags = {
#     Name = "my-subnet"
#   }
# }
#
# ## security group for eks cluster
# resource "aws_security_group" "my_sg" {
#   vpc_id = aws_vpc.my_vpc.id
#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "my-sg"
#   }
# }
#
# ## iam role for eks cluster
# resource "aws_iam_role" "my_eks_role" {
#   name = "my-eks-role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#     },
#     "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }
#
# #Policy attachment
# resource "aws_iam_role_policy_attachment" "EKS_cluster_policy_attachment" {
#   role      = aws_iam_role.my_eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   #This policy provides Kubernetes the permissions it requires to manage resources on your behalf.
#   #Kubernetes requires Ec2:CreateTags permissions to place identifying information on EC2 resources
#   #including but not limited to Instances, Security Groups, and Elastic Network Interfaces.
# }
#
# resource "aws_iam_role_policy_attachment" "EKS_service_policy_attachment" {
#   role      = aws_iam_role.my_eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   #This policy allows Amazon Elastic Container Service for Kubernetes to create and manage the necessary resources to operate EKS Clusters.
# }
#
# resource "aws_iam_role_policy_attachment" "EKS_WorkerNode_policy_attachment" {
#   role      = aws_iam_role.my_eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   #This policy allows Amazon EKS worker nodes to connect to Amazon EKS Clusters.
# }
#
# resource "aws_iam_role_policy_attachment" "EKS_CNI_policy_attachment" {
#   role      = aws_iam_role.my_eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   #This policy provides the Amazon VPC CNI Plugin (amazon-vpc-cni-k8s)
#   #the permissions it requires to modify the IP address configuration on your EKS worker nodes.
#   #This permission set allows the CNI to list, describe, and modify Elastic Network Interfaces on your behalf.
#   #More information on the AWS VPC CNI Plugin is available here: https://github.com/aws/amazon-vpc-cni-k8s
# }
#
# #create the actual EKS cluster
# resource "aws_eks_cluster" "my_cluster" {
#   name = "my-cluster"
#   role_arn = aws_iam_role.my_eks_role.arn
#   vpc_config {
#     subnet_ids = [aws_subnet.my_subnet.id, aws_subnet.my_other_subnet.id]
#     security_group_ids = [aws_security_group.my_sg.id]
#     endpoint_private_access = true
#     endpoint_public_access  = false
#   }
# }
#
# #Outputs
# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.my_cluster.endpoint
# }
#
# output "eks_cluster_certificate_authority_data" {
#   value = aws_eks_cluster.my_cluster.certificate_authority.0.data
# }
