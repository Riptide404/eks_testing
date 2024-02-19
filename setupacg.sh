#acloudguru script to setup everything
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"



(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/cloudshell-user/.bash_profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo yum groupinstall 'Development Tools' -y



brew install awscli kubernetes-cli terraform eksctl


git clone https://github.com/Riptide404/eks_testing.git

cd eks_testing

terraform init

terraform apply -auto-approve

eksctl create cluster --name dev --region us-east-1 --zones=us-east-1a,us-east-1b,us-east-1d --nodegroup-name standard-workers --node-type t3.medium --nodes 3 --nodes-min 1 --nodes-max 4 --managed

#pull in the github

#access token to github for pushing back = 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

#k8 commands next to try and get nifi to run
#should also let the cluster be public facing so we can hit it


#add ons specified in the tutorial are 
#Amazon vpc CNI
#CoreDNS
#kube-proxy