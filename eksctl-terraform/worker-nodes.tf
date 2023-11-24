
#----------------------
# variables
#----------------------

variable "eksctl-dev-cluster-ClusterSecurityGroupId" {
  description = "This variable was an imported value in the Cloudformation Template."
}

#----------------------
# resources
#----------------------

resource "aws_launch_template" "launch_template" {
  name_prefix = "k8-"
  instance_type = "t3.micro"
  user_data = base64encode(<<EOF
  #!/bin/bash
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
  EOF
  )
  
}


resource "aws_eks_node_group" "managed_node_group" {
  ami_type = "AL2_x86_64"
  cluster_name = "dev"
  instance_types = [
    "t3.medium"
  ]
  labels = {
    alpha.eksctl.io/cluster-name = "dev"
    alpha.eksctl.io/nodegroup-name = "standard-workers"
  }

  launch_template {
    id = aws_launch_template.launch_template.arn
    version = aws_launch_template.launch_template.latest_version
  }

  node_role_arn = aws_iam_role.node_instance_role.arn
  node_group_name = "standard-workers"

  scaling_config {
    desired_size = 3
    max_size = 4
    min_size = 1
  }
  subnet_ids = aws_eks_cluster.control_plane.vpc_config.subnet_ids
  tags = {
    alpha.eksctl.io/nodegroup-name = "standard-workers"
    alpha.eksctl.io/nodegroup-type = "managed"
  }
}
#data block for iam role policy
data "aws_iam_policy_document" "node_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = local.mappings["ServicePrincipalPartitionMap"][data.aws_partition.current.partition]["EC2"]
    }
  }
}

resource "aws_iam_role" "node_instance_role" {
  name = "node_instance_role"
  assume_role_policy = data.aws_iam_policy_document.node_role_policy.json
  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = {
    Name = "${local.stack_name}/NodeInstanceRole"
  }
}
