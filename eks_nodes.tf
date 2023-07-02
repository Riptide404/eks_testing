## iam role for eks cluster
resource "aws_iam_role" "my_WorkerNode_role" {
  name = "my-eks-worker-node-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role      = aws_iam_role.my_WorkerNode_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  #This policy allows Amazon EKS worker nodes to connect to Amazon EKS Clusters.
}

resource "aws_iam_role_policy_attachment" "eks_CNI_policy_attachment" {
  role      = aws_iam_role.my_WorkerNode_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  #policy mentioned in eks_environment.tf
}

resource "aws_iam_role_policy_attachment" "ecr_read_policy_attachment" {
  role      = aws_iam_role.my_WorkerNode_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  #Provides read-only access to Amazon EC2 Container Registry repositories.
}

## NodeGroup resources
resource "aws_eks_node_group" "my_node_group" {
  cluster_name = aws_eks_cluster.my_cluster.name
  node_group_name = "my-node-group"
  node_role_arn = aws_iam_role.my_WorkerNode_role.arn
  #ami_type = should eventually add this when making AMIs for the nodes

  subnet_ids  = [aws_subnet.my_subnet.id, aws_subnet.my_other_subnet.id]
  instance_types = ["t3.micro"]
  scaling_config {
    desired_size      = 2
    min_size          = 1
    max_size          = 3
  }
}
