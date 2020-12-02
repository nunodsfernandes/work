#!/bin/bash

# Update and install basics:
sudo yum update -y
sudo yum install -y conntrack
sudo yum install unzip -y

# Kubectl install
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Minkube install
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/
sudo mv /usr/local/bin/minikube /usr/bin/

#Docker install
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)
sudo systemctl start docker
sudo systemctl enable docker

# Install HELM and update the repos
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add couchdb https://apache.github.io/couchdb-helm
helm repo update


# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


# Create directories for Filebeat
sudo mkdir /usr/share/
sudo mkdir /usr/share/filebeat
sudo mkdir /var/lib/
sudo mkdir /var/lib/filebeat-data

sudo chmod -R 777 /usr/share/filebeat
sudo chmod -R 777 /var/lib/filebeat-data

clear

echo ""
echo ""
echo "Part 1 of the setup is finished. Please logout and log back in to re-evaluate Docker user permissions.."
echo "After you log back in, please run part 2 of the script using the following command:"
echo "curl -fsSL https://raw.githubusercontent.com/NunoDSFernandes/NxAutomation/master/Scripts/Minikube_2.sh | sh"
echo ""
exit
