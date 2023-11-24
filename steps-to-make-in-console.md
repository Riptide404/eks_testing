need iam role for the eks Cluster
need vpc with multiple subnets (public and private if you want both access)
need to point kubeconfig at the cluster so you can get info about it
need iam role for node roles
  attach these policies to that node role
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
add node group to cluster with the node iam role you made earlier




node group details
has
- node group arn
- created
- autoscaling group name
- node iam role arn  -> AmazonEC2ContainerRegistryReadOnly
                        AmazonEKS_CNI_Policy
                        AmazonEKSWorkerNodePolicy
                        AmazonSSMManagedInstanceCore
                        Trust relationships:
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
                        tags:
                          alpha.eksctl.io/nodegroup-name	standard-workers
                          alpha.eksctl.io/cluster-name	dev
                          eksctl.cluster.k8s.io/v1alpha1/cluster-name	dev
                          alpha.eksctl.io/nodegroup-type	managed
                          alpha.eksctl.io/eksctl-version	0.158.0
                          Name	eksctl-dev-nodegroup-standard-workers/NodeInstanceRole
- capacity type - > one-demand
- Desired size 3
- minimum size 1
- maximum size 4
- subnets -> 3 subnets
- remote access = off

subnets - pirvate us east A B D
        - public us east A B D

vpc routtables for private and 