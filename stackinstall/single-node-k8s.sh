#!/bin/bash

# This is prepared for a Centos 7 machine that will be used as a Master Node.
# Prepare environment


# Put SELinux in permissive mode and load br_netfilter
sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter


# Disable swap and comment it out on fstab
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# Create proper hosts file for the aliases
cat <<EOF >  /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF


# Disable FW and prep net bridge iptable configuration
service firewalld stop
systemctl stop firewalld
systemctl disable firewalld
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF >  /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


# Install and start components and services, Docker, Kubeadm and others
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)
systemctl start docker kubelet && systemctl enable docker kubelet

yum update -y && yum upgrade && yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add couchdb https://apache.github.io/couchdb-helm
helm repo update


# Pre-pull the images for kubeadm and init the cluster
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 -v=9
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config


#Deploy the CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-


# Create the NFS Storage Controller on the master node
mkdir -p /srv/nfs/kubedata
adduser nfsnobody
chown nfsnobody: /srv/nfs/kubedata
yum install nfs-utils -y
systemctl enable nfs-server
systemctl start nfs-server
echo /srv/nfs/kubedata *(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure) >> /etc/exports
exportfs -rav

clear
