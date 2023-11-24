
terraform {
  required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.23.0"
      }
  }
}


provider "aws" {
  region = var.region
}


variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}


#------------------------------------------------------------------------------------
# whole thing looks good we will see what happens when we try to deploy to aws
#------------------------------------------------------------------------------------

data "aws_partition" "current" {}


locals {
  mappings = {
    ServicePrincipalPartitionMap = {
      aws = {
        EC2 = "ec2.amazonaws.com"
        EKS = "eks.amazonaws.com"
        # EKSFargatePods = "eks-fargate-pods.amazonaws.com"
      }
      aws-cn = {
        EC2 = "ec2.amazonaws.com.cn"
        EKS = "eks.amazonaws.com"
        # EKSFargatePods = "eks-fargate-pods.amazonaws.com"
      }
      aws-iso = {
        EC2 = "ec2.c2s.ic.gov"
        EKS = "eks.amazonaws.com"
        # EKSFargatePods = "eks-fargate-pods.amazonaws.com"
      }
      aws-iso-b = {
        EC2 = "ec2.sc2s.sgov.gov"
        EKS = "eks.amazonaws.com"
        # EKSFargatePods = "eks-fargate-pods.amazonaws.com"
      }
      aws-us-gov = {
        EC2 = "ec2.amazonaws.com"
        EKS = "eks.amazonaws.com"
        # EKSFargatePods = "eks-fargate-pods.amazonaws.com"
      }
    }
  }
  stack_name = "eksctl-dev-cluster"
}

#----------------------
# resources
#----------------------

resource "aws_security_group" "cluster_shared_node_security_group" {
  description = "Communication between all nodes in the cluster"
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}/ClusterSharedNodeSecurityGroup"
  }
}
#the actula eks cluster resource that is in aws it shows up in the console under aws eks
#we call it a control plane because this is the central controller of the eks cluster
#10/17: this looks good
resource "aws_eks_cluster" "control_plane" {
  kubernetes_network_config {
    ip_family = "ipv4"
  }
  name = "dev"
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = false
    security_group_ids = [
      aws_security_group.control_plane_security_group.arn
    ]
    subnet_ids = [
      aws_subnet.subnet_private_useast1_a.id,
      aws_subnet.subnet_private_useast1_b.id,
      aws_subnet.subnet_private_useast1_d.id
    ]
  }
  role_arn = aws_iam_role.service_role.arn
  version = "1.25"
  tags = {
    Name = "${local.stack_name}/ControlPlane"
  }
}
#no real controls just has the connection between control plane and worker nodes
#10/20: dont care looks good
resource "aws_security_group" "control_plane_security_group" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id = aws_vpc.vpc.arn

  ingress {
    description                  = "Allow managed and unmanaged nodes to communicate with each other (all ports)"
    from_port                    = 0
    to_port                      = 65535
    protocol                     = "-1"
    security_groups              = [aws_eks_cluster.control_plane.cluster_id]
  }

  ingress {
    description = "Allow nodes to communicate with each other (all ports)"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow unmanaged nodes to communicate with control plane (all ports)"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    security_groups = [aws_eks_cluster.control_plane.cluster_id]
  }
  tags = {
    Name = "${local.stack_name}/ControlPlaneSecurityGroup"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Name = "${local.stack_name}/InternetGateway"
  }
}

resource "aws_route" "nat_private_subnet_route_useast1_a" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.association_id
  route_table_id = aws_route_table.private_route_table_useast1_a.id
}

resource "aws_route" "nat_private_subnet_route_useast1_b" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.association_id
  route_table_id = aws_route_table.private_route_table_useast1_b.id
}

resource "aws_route" "nat_private_subnet_route_useast1_d" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.association_id
  route_table_id = aws_route_table.private_route_table_useast1_d.id
}

data "aws_iam_policy_document" "cloudwatch_metrics" {
  statement {
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "policy_cloud_watch_metrics" {
  name = "${local.stack_name}-PolicyCloudWatchMetrics"
  description = "aws policy for putting metric data into cloudwatch on all resources"
  policy = data.aws_iam_policy_document.cloudwatch_metrics.json
}

data "aws_iam_policy_document" "elb_permissions_policy" {
  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways"
    ]
    resources = "*"
    effect = "Allow"
  }
}

resource "aws_iam_policy" "policy_elb_permissions" {
  name = "${local.stack_name}-PolicyELBPermissions"
  policy = data.aws_iam_policy_document.elb_permissions_policy.json
  description = "elb permissions to describe properties of ec2 insances"
}

resource "aws_route_table" "private_route_table_useast1_a" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}/PrivateRouteTableUSEAST1A"
  }
}

resource "aws_route_table" "private_route_table_useast1_b" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}/PrivateRouteTableUSEAST1B"
  }
}

resource "aws_route_table" "private_route_table_useast1_d" {
  vpc_id = aws_vpc.vpc.arn
  tags = {
    Name = "${local.stack_name}/PrivateRouteTableUSEAST1D"
  }
}

# resource "aws_route_table" "public_route_table" {
#   vpc_id = aws_vpc.vpc.arn
#   tags = {
#     Name = "${local.stack_name}/PublicRouteTable"
#   }
# }

# resource "aws_route" "public_subnet_route" {
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id = aws_internet_gateway.internet_gateway.id
#   route_table_id = aws_route_table.public_route_table.id
# }

resource "aws_route_table_association" "route_table_association_private_useast1_a" {
  route_table_id = aws_route_table.private_route_table_useast1_a.id
  subnet_id = aws_subnet.subnet_private_useast1_a.id
}

resource "aws_route_table_association" "route_table_association_private_useast1_b" {
  route_table_id = aws_route_table.private_route_table_useast1_b.id
  subnet_id = aws_subnet.subnet_private_useast1_b.id
}

resource "aws_route_table_association" "route_table_association_private_useast1_d" {
  route_table_id = aws_route_table.private_route_table_useast1_d.id
  subnet_id = aws_subnet.subnet_private_useast1_d.id
}

# resource "aws_route_table_association" "route_table_association_public_useast1_a" {
#   route_table_id = aws_route_table.public_route_table.id
#   subnet_id = aws_subnet.subnet_public_useast1_a.id
# }

# resource "aws_route_table_association" "route_table_association_public_useast1_b" {
#   route_table_id = aws_route_table.public_route_table.id
#   subnet_id = aws_subnet.subnet_public_useast1_b.id
# }

# resource "aws_route_table_association" "route_table_association_public_useast1_d" {
#   route_table_id = aws_route_table.public_route_table.id
#   subnet_id = aws_subnet.subnet_public_useast1_d.id
# }


data "aws_iam_policy_document" "service_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type    = "Service"
      identifiers = local.mappings["ServicePrincipalPartitionMap"][data.aws_partition.current.partition]["EKS"]
    }
  }
}

#need to investigate this and make sure it achieve what we want
resource "aws_iam_role" "service_role" {
  assume_role_policy = data.aws_iam_policy_document.service_role_policy.json
  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
  tags = {
    Name = "${local.stack_name}/ServiceRole"
  }
}

resource "aws_subnet" "subnet_private_useast1_a" {
  availability_zone = "us-east-1a"
  cidr_block = "192.168.96.0/19"
  vpc_id = aws_vpc.vpc.arn
  tags = {
    kubernetes.io/role/internal-elb = "1"
    Name = "${local.stack_name}/SubnetPrivateUSEAST1A"
  }
}

resource "aws_subnet" "subnet_private_useast1_b" {
  availability_zone = "us-east-1b"
  cidr_block = "192.168.128.0/19"
  vpc_id = aws_vpc.vpc.arn
  tags = {
    kubernetes.io/role/internal-elb = "1"
    Name = "${local.stack_name}/SubnetPrivateUSEAST1B"
  }
}

resource "aws_subnet" "subnet_private_useast1_d" {
  availability_zone = "us-east-1d"
  cidr_block = "192.168.160.0/19"
  vpc_id = aws_vpc.vpc.arn
  tags = {
    kubernetes.io/role/internal-elb = "1"
    Name = "${local.stack_name}/SubnetPrivateUSEAST1D"
  }
}

# resource "aws_subnet" "subnet_public_useast1_a" {
#   availability_zone = "us-east-1a"
#   cidr_block = "192.168.0.0/19"
#   map_public_ip_on_launch = True
#   vpc_id = aws_vpc.vpc.arn
#   tags = {
#     kubernetes.io/role/elb = "1"
#     Name = "${local.stack_name}/SubnetPublicUSEAST1A"
#   }
# }

# resource "aws_subnet" "subnet_public_useast1_b" {
#   availability_zone = "us-east-1b"
#   cidr_block = "192.168.32.0/19"
#   map_public_ip_on_launch = True
#   vpc_id = aws_vpc.vpc.arn
#   tags = {
#     kubernetes.io/role/elb = "1"
#     Name = "${local.stack_name}/SubnetPublicUSEAST1B"
#   }
# }

# resource "aws_subnet" "subnet_public_useast1_d" {
#   availability_zone = "us-east-1d"
#   cidr_block = "192.168.64.0/19"
#   map_public_ip_on_launch = True
#   vpc_id = aws_vpc.vpc.arn
#   tags = {
#     kubernetes.io/role/elb = "1"
#     Name = "${local.stack_name}/SubnetPublicUSEAST1D"
#   }
# }

resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${local.stack_name}/VPC"
  }
}

resource "aws_vpn_gateway" "vpn_gateway" {
  tags = {
    Name = "eks-vpn-gateway"
  }
}

resource "aws_vpn_gateway_attachment" "vpc_gateway_attachment" {
  vpc_id = aws_vpc.vpc.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway.id
}

#----------------------
# outputs
#----------------------

output "arn" {
  value = aws_eks_cluster.control_plane.arn
}

output "certificate_authority_data" {
  value = aws_eks_cluster.control_plane.certificate_authority
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.control_plane.cluster_id
}

output "cluster_stack_name" {
  value = local.stack_name
}

output "endpoint" {
  value = aws_eks_cluster.control_plane.endpoint
}

output "feature_nat_mode" {
  value = "Single"
}

output "security_group" {
  value = aws_security_group.control_plane_security_group.arn
}

output "service_role_arn" {
  value = aws_iam_role.service_role.arn
}

output "shared_node_security_group" {
  value = aws_security_group.cluster_shared_node_security_group.arn
}

output "subnets_private" {
  value = join(",", [aws_subnet.subnet_private_useast1_a.id, aws_subnet.subnet_private_useast1_b.id, aws_subnet.subnet_private_useast1_d.id])
}

# output "subnets_public" {
#   value = join(",", [aws_subnet.subnet_public_useast1_a.id, aws_subnet.subnet_public_useast1_b.id, aws_subnet.subnet_public_useast1_d.id])
# }

output "vpc" {
  value = aws_vpc.vpc.arn
}