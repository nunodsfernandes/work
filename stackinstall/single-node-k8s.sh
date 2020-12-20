# This is prepared for single machine that will be used as a single node.
# Also, this MUST be run as root.


# Put SELinux in permissive mode and load br_netfilter
sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter


# Disable swap and comment it out on fstab
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


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


# Install Tools
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
systemctl daemon-reload
systemctl restart kubelet

# (Install Docker CE)
yum install -y yum-utils device-mapper-persistent-data lvm2

# Add the Docker repository
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
yum update -y && yum install -y containerd.io docker-ce docker-ce-cli


## Create /etc/docker
mkdir /etc/docker

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Create /etc/systemd/system/docker.service.d
mkdir -p /etc/systemd/system/docker.service.d


# Restart Docker
systemctl start docker && systemctl enable docker
usermod -aG docker $(whoami)
systemctl daemon-reload
systemctl restart docker


# Pre-pull the images for kubeadm and init the cluster
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 -v=9
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config


#Deploy the CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-

