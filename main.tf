# #what makes an eks cluster
# ##
# ##
# ##
#
# variable "region" {
#   description = "AWS region"
#   type        = string
#   default     = "us-east-1"
# }
#
# variable "AccessKey" {
#   description = "AWS Access Key ID"
#   type        = string
#   sensitive   = true
# }
#
# variable "SecretKey" {
#   description = "AWS Secret Access Key"
#   type        = string
#   sensitive   = true
# }
#
#
# # eks cluster itself
#
# #route 53 dns name (autocreated when an eks cluster is created)
#
# #EC2s for worker nodes
#
# #ElasticBlock storage (EBS) for persistent volumes that can be mounted by pods for workloads
#
# #EFS (optional sometimes they are better than EBS)
#
# #ALB (applicaiton load balancer) provisioned by the eks cluster when ingress resources are created (inboand access)
#
# #NLB (network Load Balancer) [ALB or NLB] required if an applicaiton requires ingress not supported by ALB
#
# #IAM controls for things to be able to talk to things and for the eks cluster to be secure
#
# #ECR registry store and utilize container images
#
# #KMS encrypt container images and ebs volumes plus more
#
# #cloudwatch, send logs to logging
#
# #vpc everything attatched to eks needs to be placed in a vpc
#
# #ec2 autoscaling
#
# #vpc Endpoints for services not hosted in the same vpc
#
# #ACM certs for ALB
#
# #Security Groups
#
# #SSM utilized for ConfigMap api object that is used to store nonconfidential data in keyvalue pairs equivalent to docker compose files eg. configmap/configure-pod.yaml
#
# #Secrets manager helps with Secret things like passwords or tokens
#
# ####required kubernetes add ons
# #aws_vpc_cni
#
# #aws_cloudwatch-metrics container insights
#
# #aws-coredns supports contianer to container dns
#
# #aws-ebs-csi it's a driver that is needed for container orchestrators to manage ebs lifecycles
#
# #aws-efs-csi-driver  same as above but for efs
#
# #aws-kube-proxy maintains network rules on each ec2 node
#
# #aws-load-balancer-controller
#
# #cert-manager
#
# #secrets-store-csi-driver csi = container storage interface volume helps with container type secrets storage
#
# #csi-secrets-store-provider-aws secret store CSI driver allows the user to store asecret contents in an aws KMS instance and use the secrets store CSI driver to interface and mount them to k8 pods
#
# #external-dns k8 add on that acan automate the management of DNS records based on Ingress and Service resources
#
# #istio* required for pod to pod encryption, mandatory in the cloud env pt2 helps in managing microservices and run distributed apps
#
