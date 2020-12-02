#!/bin/bash

# This is prepared for a Centos 7 machine that will be used as a Master Node.
# Prepare environment


# Put SELinux in permissive mode and load br_netfilter
sudo sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo modprobe br_netfilter


# Disable swap and comment it out on fstab
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# Create proper hosts file for the aliases
sudo cat <<EOF >  /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF


# Disable FW and prep net bridge iptable configuration
sudo service firewalld stop
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF >  /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


# Install and start components and services, Docker, Kubeadm and others
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)
sudo systemctl start docker kubelet && systemctl enable docker kubelet

sudo yum update -y && yum upgrade && yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo add couchdb https://apache.github.io/couchdb-helm
sudo helm repo update


# Pre-pull the images for kubeadm and init the cluster
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 -v=9
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#Deploy the CNI (Flannel)
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sudo kubectl taint nodes --all node-role.kubernetes.io/master-


# Create the NFS Storage Controller on the master node
sudo mkdir -p /srv/nfs/kubedata
sudo adduser nfsnobody
sudo chown nfsnobody: /srv/nfs/kubedata
sudo yum install nfs-utils -y
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
sudo echo /srv/nfs/kubedata *(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure) >> /etc/exports
sudo exportfs -rav

clear
