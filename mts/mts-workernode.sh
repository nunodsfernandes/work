#!/bin/bash

# This is prepared for a Centos 7 machine that will be used as a Worker Node.

# Prepare environment

# Put SELinux in permissive mode, stop firewall, etc...
sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
setenforce 0
service firewalld stop
systemctl stop firewalld
systemctl disable firewalld
swapoff -a
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

cat <<EOF >  /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.100.15 masternode
192.168.100.16 worker1
192.168.100.17 worker2
EOF

sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter

# Net bridge iptable configuration
cat <<EOF >  /etc/sysctl.d/kube.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Docker Kubeadm and others
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)

# Install and start components and services
yum update -y && yum upgrade -y && yum install -y kubelet kubeadm nfs-utils
systemctl start docker kubelet && systemctl enable docker kubelet


# Install AWS CLI
yum install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
