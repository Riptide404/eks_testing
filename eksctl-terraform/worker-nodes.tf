
#----------------------
# resources
#----------------------

resource "aws_launch_template" "launch_template" {
  name_prefix = "k8-"
  instance_type = "t3.micro"
  user_data = base64encode(<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
/etc/eks/bootstrap.sh dev

--==MYBOUNDARY==--
EOF
 )
  
}


resource "aws_eks_node_group" "managed_node_group" {
  ami_type = "AL2_x86_64"
  cluster_name = "dev"
  labels = {
    cluster-name = "dev"
    nodegroup-name = "standard-workers"
  }

  launch_template {
    id = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  node_role_arn = aws_iam_role.node_instance_role.arn
  node_group_name = "standard-workers"

  scaling_config {
    desired_size = 3
    max_size = 4
    min_size = 1
  }
  #this should have been made dynamic
  subnet_ids = [
      aws_subnet.subnet_private_useast1_a.id,
      aws_subnet.subnet_private_useast1_b.id,
      aws_subnet.subnet_private_useast1_d.id
  ]
  tags = {
    nodegroup-name = "standard-workers"
    nodegroup-type = "managed"
  }
  #need this resource to not build until the control plane is built
  depends_on = [
    aws_eks_cluster.control_plane,
    aws_iam_role.node_instance_role
    ]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_instance_role" {
  name = "node_instance_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = {
    Name = "NodeInstanceRole"
  }
}
