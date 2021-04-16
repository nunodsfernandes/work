#!/bin/bash

# Root check
[ "$(whoami)" != 'root' ] && ( echo "This script MUST be run as root" ; exit 1 )

# Color definitions
    RED="\e[1;31m"
    GREEN="\e[1;32m"
    BLUE="\e[1;34m"
    YELLOW="\e[1;33m"
    PURPLE="\e[1;35m"
    NC="\e[0m" # No Color


#************ FUNCTIONS
function check_connectivity() {

    countconnectcheck=$((countconnectcheck+1))

    if [[ $(timeout 10s curl -s $1) ]]; then
      echo -e "${GREEN}PASS${NC}| $2"
	accesstracking=$((accesstracking+1))
    else
      echo -e "${RED}FAIL${NC}| $2"
	accesstracking=$((accesstracking-1))
	accessfailcount=$((accessfailcount+1))
    fi
}

function check_proxy() {
    if [[ $(env | grep proxy) ]]; then
    env | grep proxy
    else
    echo -e "No proxies defined on the environment variables."
    fi
}

function check_ifconfig {
    if [[ $(timeout 5s curl -s curl ifconfig.me) ]]; then
      pub_ip_outside=$(timeout 5s curl -s ifconfig.me)
    else
      pub_ip_outside="None"
    fi
}



#************ CHECKS

### Clear all vars and screen
CONNECT_CHECK=""
PROXYDEFINED=""
pub_ip_outside=""
cansetup=""
countconnectcheck=0
accessfailcount=0
accesstracking=0
cansetup=0
CidrUserChoice=""
clear


### Start the checks
printf " ${RED} -----:) CONNECTIVITY TEST (:----- ${NC} \n"
echo ""
echo ""


### Place all the adapters on an array:
printf " ${YELLOW} *** NETWORK INTERFACES *** ${NC} \n"
  network_adapters_on_machine=()
    while IFS= read -r line; do
       network_adapters_on_machine+=( "$line" )
    done < <( ip -br -c addr show | egrep -v DOWN | egrep -v UNKNOWN | cut -f1 -d"/" )


### Print the array on screen - Select single value by changing the "@" for the array  component number
printf '%s\n' "${network_adapters_on_machine[@]}"
echo ""
echo ""

### Check for internet connectivity by looking at Google and getting the external IP for the machine
printf " ${YELLOW} *** INTERNET CONNECTIVITY *** ${NC} \n"
check_ifconfig
printf "${PURPLE}Public IP: ${NC} %s \n" $pub_ip_outside
check_connectivity google.com "Google.com"
echo ""
echo ""


### Check for connectivity by: function address "description"
printf " ${YELLOW} *** REPOSITORIES (HTTPS check) *** ${NC} \n"
check_connectivity https://aws.amazon.com "Amazon Web Services"
check_connectivity https://github.com "GitHub (public)"
check_connectivity https://cloud.google.com "Google Cloud Container Registry"
check_connectivity https://www.docker.elastic.co "Docker Elastic"
check_connectivity https://k8s.gcr.io "K8s GCR"
check_connectivity https://quay.io "Quay.io"
echo ""
echo ""

### Check for the environment variables
printf " ${YELLOW} *** ENVIRONMENT PROXY SETTINGS *** ${NC} \n"
check_proxy
echo ""
echo ""




##############################  Place code to execute when all connectivity is OK:

### Counter vs Access check:
if [ "$countconnectcheck" = "$accesstracking" ]; then
   printf "${GREEN} %s TESTS COMPLETED. CONNECTIVITY IS OK. ${NC} \n" $accesstracking
   echo ""
   echo ""
   cansetup=1
echo ""
echo ""


printf " ${YELLOW} *** ENVIRONMENT PROXY SETTINGS *** ${NC} \n"
check_proxy
echo ""
echo ""




### Disclaimer about CIDR ranges
printf " ${YELLOW} -----:)  STACK SETUP  (:----- ${NC} \n"
echo ""
printf "${NC}Insert the values for the stack setup:${NC} \n"
printf "${NC}Please use the ${GREEN}0.0.0.0/16 format${NC} when defining the range. Please use /16 for the suffix. ${NC} \n"
printf "${NC}As an example, a classic CIDR block on a K8s stack is:${NC} ${GREEN}192.168.0.0/16${NC} \n"
echo ""
printf "${RED}IMPORTANT:${NC}Please refrain from using the same IP range as the host, as this will probably cause issues. \n"
echo ""

### Confirm if the CIDR block is correctly set on the machine:
read -p 'Kubeadm Stack CIDR block: ' kubeadm_cidr_block
while [[ "$kubeadm_cidr_block" == "" ]]
        do
            read -p 'Kubeadm Stack CIDR block: ' kubeadm_cidr_block
        done
echo ""
echo ""

printf " ${BLUE}You have configured the CIDR block for the K8s stack to: ${NC} %s \n" $kubeadm_cidr_block
read -p "   - Is this setting ok? [y/n]: " CidrUserChoice
        while [[ "$CidrUserChoice" != "y" && "$CidrUserChoice" != "Y" ]]
        do
            read -p 'Kubeadm Stack CIDR block: ' kubeadm_cidr_block
            echo ""
	    printf " ${BLUE} You have reconfigured the CIDR block to: ${NC} %s \n" $kubeadm_cidr_block
            echo ""
            read -p "   - Is this ok? [y/n]: " CidrUserChoice
        done





##############################  CLUSTER SETUP PHASE


### Create directory structure

mkdir $HOME/saasops-tools
mkdir /etc/docker
mkdir -p /etc/systemd/system/docker.service.d
mkdir -p $HOME/.kube
mkdir $HOME/eo-install


### Build configuration files

cat <<EOF | sudo tee -a $HOME/saasops-tools/custom_calico_resources.yaml > /dev/null
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: $kubeadm_cidr_block
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF

cat <<EOF | sudo tee -a /etc/yum.repos.d/kubernetes.repo > /dev/null
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


cat <<EOF | sudo tee -a /etc/docker/daemon.json > /dev/null
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

cat <<EOF | sudo tee -a /etc/sysctl.d/kube.conf > /dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF


cat <<EOF | sudo tee -a $HOME/eo-install/pv.yaml  > /dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-1
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv1/"
    
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-2
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv2/"    
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-3
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv3/"
    
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-4
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv4/"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-5
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv5/"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eo-persistent-volume-6
spec:
  storageClassName: standard
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/eo-pv6/"
EOF



### Reload sysctl configuration variables
sysctl --system
sleep 3


### Put SELinux in permissive mode and load br_netfilter
sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter


### Disable swap and comment it out on fstab
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a



### Disable firewall.
#   This will later be changed to allow configuration of the stack with Firewalld active and configured.
systemctl stop firewalld
systemctl disable firewalld



### Deploy basic software packages

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum update -y
yum install -y yum-utils device-mapper-persistent-data lvm2 containerd.io docker-ce docker-ce-cli unzip kubelet kubeadm kubectl --disableexcludes=kubernetes

sleep 5

# Start and Enable containerization
systemctl start kubelet
systemctl start docker
usermod -aG docker $(whoami)
systemctl daemon-reload
systemctl restart docker

# Symlinks
systemctl enable kubelet
systemctl enable docker


### Prepare cluster deployment
kubeadm config images pull

kubeadm init --pod-network-cidr=$kubeadm_cidr_block -v=9

sleep 5

# Copy configuration files to the home kubeconfig

cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

sleep 5

if [[ $(kubectl get pods -A) =~ "refused" ]]; then
  printf "${RED} STACK DEPLOYMENT FAILED!${NC} \n"
  exit 0
fi


# Deploy Calico networking
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f $HOME/saasops-tools/custom_calico_resources.yaml # modified file with cluster CIDR


# Make the main node a master node (untaint)
kubectl taint nodes --all node-role.kubernetes.io/master-


# Prepare the volumes for the EO deployment using local storage on the master node
mkdir -p /data/eo-pv1
mkdir -p /data/eo-pv2
mkdir -p /data/eo-pv3
mkdir -p /data/eo-pv4
mkdir -p /data/eo-pv5
mkdir -p /data/eo-pv6

chmod 777 /data/eo-pv1
chmod 777 /data/eo-pv2
chmod 777 /data/eo-pv3
chmod 777 /data/eo-pv4
chmod 777 /data/eo-pv6


# Apply the configuration to the cluster
kubectl apply -f $HOME/eo-install/pv.yaml


# Deploy Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh



# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


# Check if controller-manager   Unhealthy   Get "http://127.0.0.1:10252/healthz": dial tcp 127.0.0.1:10252: connect: connection refused
# Check if scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused
# Check if etcd-0               Healthy     {"health":"true"}
# Fix it if found...
if [[ $(kubectl get cs) =~ "connection refused" ]]; then
  sed -i '/- --port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i '/- --port=0/d' /etc/kubernetes/manifests/kube-controller-manager.yaml
  systemctl restart kubelet
  sleep 3
  printf "${YELLOW} kube-scheduler and kube-controller-manager found unhealthy after setup.${NC} \n"
  printf "${YELLOW} Issue was fixed:${NC} \n"
  kubectl get cs
  sleep 5
fi


# Get the cluster information
kubectl get all



##############################  Place code to execute when all connectivity is NOT OK:

else
   printf "${RED} %s TESTS FAILED. CONNECTIVITY IS NOT OK! ${NC} \n" $accessfailcount
   echo "Please check connectivity before setting up the K8s stack."
   echo ""
   cansetup=0
fi