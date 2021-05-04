#!/bin/bash

######################################################
#                                                    #
#  Auto K8s Deployment script - Single node cluster  #
#  NF - CTG SaaS Operations                          #
#                                                    #
######################################################

# timer setup
SECONDS=0

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

    clusterchecks_count=$((clusterchecks_count+1))

    if [[ $(timeout 10s curl -s $1) ]]; then
      echo -e "${GREEN}PASS${NC}| $2"
        clusterchecks_success=$((clusterchecks_success+1))
    else
      echo -e "${RED}FAIL${NC}| $2"
        clusterchecks_fail=$((clusterchecks_fail+1))
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
# Clear all vars and screen
CONNECT_CHECK=""
PROXYDEFINED=""
pub_ip_outside=""
cansetup=""
clusterchecks_count=""
accessfailcount=""
clusterchecks_count=""
clusterchecks_success=""
clusterchecks_fail=""
clusterchecks_tracking=""
cansetup=""
CidrUserChoice=""
memoryonmachine=""
rootsizedisk=""


clear
cat << "EOF"
  ___________________________________________
 / [] Autostack - by NF                |F]|!"|
|""""""""""""""""""""""""""""""""""""""""""|"|
| Kubernetes single stack deployment tool  |_|
| Feedback and cookies are welcome!        | |
|                                          | |
|                       CTG SaaS Ops       |_|
|__________________________________________|/
EOF

#Start the checks
printf " ${RED} -----:) TESTING STAGE (:----- ${NC} \n"
echo ""
echo ""
printf "${YELLOW}***************************************** CPU / MEM / HDD ${NC} \n"
echo ""


# Check CPUs
if [[ $(nproc) -lt "4" ]]; then
    printf "${RED}FAIL${NC} - This machine has only %s Cores and does meet minimum requirements (4 Cores) \n" $(nproc)
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_fail=$((clusterchecks_fail+1))
else
    printf "${GREEN}PASS${NC} - CPU Count: %s - OK to proceed ${NC}\n" $(nproc)
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_success=$((clusterchecks_success+1))
fi


# Check memory
memoryonmachine=$((cat /proc/meminfo | grep MemTotal | rev | cut -c3- | rev | cut -d':' -f2 ) | while read KB dummy;do echo $((KB/1024));done)
if [[ "$memoryonmachine" -lt "7500" ]]; then
    printf "${RED}FAIL${NC} - This machine has only %sMB of memory${NC} \n" $memoryonmachine
    printf "${YELLOW}WARNING${NC} - It is HIGHLY recommended to provision at least 8GB ram per node!${NC} \n"
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_fail=$((clusterchecks_fail+1))
else
    printf "${GREEN}PASS${NC} - Mem Count: %s MB - OK to proceed ${NC}\n" $memoryonmachine
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_success=$((clusterchecks_success+1))
fi


# Check root disk size
rootsizedisk=$(fdisk -l | grep root | cut -d':' -f2 | cut -d. -f1-1)
if [[ "$rootsizedisk" -lt "100" ]]; then
    printf "${RED}FAIL${NC} - This machine has only %sGB of disk on the root partition${NC} \n" $rootsizedisk
    printf "${YELLOW}WARNING${NC} - It is HIGHLY recommended to provision at least 100GB disk size per node!${NC} \n"
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_fail=$((clusterchecks_fail+1))
else
    printf "${GREEN}PASS${NC} - This machine has %sGB of memory${NC}\n" $rootsizedisk
    printf "${GREEN}PASS${NC} - OK to proceed ${NC}\n"
        clusterchecks_count=$((clusterchecks_count+1))
        clusterchecks_success=$((clusterchecks_success+1))
fi



echo ""
# Check Connectivity
printf "${YELLOW}***************************************** NETWORK INTERFACES ${NC} \n"
echo ""
# Place all the adapters on an array:
  network_adapters_on_machine=()
    while IFS= read -r line; do
       network_adapters_on_machine+=( "$line" )
    done < <( ip -br -c addr show | egrep -v DOWN | egrep -v UNKNOWN | cut -f1 -d"/" )

# Print the array on screen - Select single value by changing the "@" for the array  component number
printf '%s\n' "${network_adapters_on_machine[@]}"

echo ""

# Check for internet connectivity by looking at Google and getting the external IP for the machine
printf "${YELLOW}***************************************** INTERNET CONNECTIVITY ${NC} \n"
echo ""
check_ifconfig
printf "${PURPLE}Public IP: ${NC} %s \n" $pub_ip_outside
check_connectivity google.com "Google.com"

echo ""

printf "${YELLOW}***************************************** REPOSITORIES (HTTPS check) ${NC} \n"
echo ""
# Check for connectivity by: function address "description"

check_connectivity https://aws.amazon.com "Amazon Web Services"
check_connectivity https://github.com "GitHub (public)"
check_connectivity https://cloud.google.com "Google Cloud Container Registry"
check_connectivity https://www.docker.elastic.co "Docker Elastic"
check_connectivity https://k8s.gcr.io "K8s GCR"
check_connectivity https://quay.io "Quay.io"

echo ""

printf "${YELLOW}***************************************** ENVIRONMENT PROXY SETTINGS ${NC} \n"
echo ""
# Check for the environment variables
check_proxy

echo ""




######################################### DISCLAIMER

### Counter vs Access check: ------------------------ 
if [ "$clusterchecks_count" = "$clusterchecks_success" ]; then
   printf "${GREEN} %s TESTS COMPLETED. CONFIGURATION IS OK. ${NC} \n" $clusterchecks_count
        else
   echo ""
   printf "${RED} ******************* !!! WARNING !!! ******************* \n ${NC}"
   printf "${RED} %s TESTS FAILED. SOME CHECKS ARE NOT OK! ${NC} \n" $clusterchecks_fail
   echo ""
   printf "${YELLOW}WARNING${NC} If you continue, the cluster might fail or be unusable. \n"
   printf "No changes have yet been made to the machine."
   echo ""
   read -p "Do you wish to STOP NOW and correct any pending issues? [y/n]: " forceUserChoice
        while [[ "$forceUserChoice" != "n" && "$forceUserChoice" != "N" ]]
        do
            exit
        done
fi

######################################### DISCLAIMER



##############################  Place code to execute when all the setup is good to go:

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
            echo "No input present...."
            read -p 'Kubeadm Stack CIDR block: ' kubeadm_cidr_block
        done
echo ""
echo ""

printf " ${BLUE}You have configured the CIDR block for the K8s stack to: ${NC} %s \n" $kubeadm_cidr_block
read -p "- Is this correct? [y/n]: " CidrUserChoice
        while [[ "$CidrUserChoice" != "y" && "$CidrUserChoice" != "Y" ]]
        do
            read -p 'Kubeadm Stack CIDR block: ' kubeadm_cidr_block
            echo ""
	    printf "${BLUE}You have reconfigured the CIDR block to: ${NC} %s \n" $kubeadm_cidr_block
            echo ""
            read -p "- Is this correct? [y/n]: " CidrUserChoice
        done


##############################  CLUSTER SETUP PHASE
echo ""
echo ""
printf "${BLUE}***************************************** ${NC} - Creating file structure and configuration files \n"

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


echo ""
echo ""
printf "${BLUE}***************************************** ${NC} - Environment setup \n"

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
echo ""
echo ""
printf "${BLUE}***************************************** ${NC} - Deploying tools \n"


yum update -y
yum install -y yum-utils device-mapper-persistent-data lvm2 containerd.io docker-ce docker-ce-cli unzip kubelet kubeadm kubectl --disableexcludes=kubernetes
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


sleep 5


printf "${BLUE}***************************************** ${NC} - Starting container gremlins \n"
# Start and Enable containerssssss
systemctl start kubelet
systemctl start docker
usermod -aG docker $(whoami)
systemctl daemon-reload
systemctl restart docker

# Symlinks
systemctl enable kubelet
systemctl enable docker

echo ""
echo ""
printf "${BLUE}***************************************** ${NC} - Starting cluster deployment \n"

### Prepare cluster deployment
kubeadm config images pull
kubeadm init --pod-network-cidr=$kubeadm_cidr_block -v=9

sleep 3

# Copy configuration files to the home kubeconfig

cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

sleep 3

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
chmod 777 /data/eo-pv5
chmod 777 /data/eo-pv6


# Apply the configuration to the cluster
kubectl apply -f $HOME/eo-install/pv.yaml


# Check if controller-manager   Unhealthy   Get "http://127.0.0.1:10252/healthz": dial tcp 127.0.0.1:10252: connect: connection refused
# Check if scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused
# Check if etcd-0               Healthy     {"health":"true"}
# Fix it if found...

if [[ $(kubectl get cs) == *"connection refused"* ]]; then
  echo ""
  echo ""
  printf "${YELLOW}WARNING${NC} - kube-scheduler and kube-controller-manager found unhealthy after setup. \n"
  printf "${BLUE} INFO ${NC} - Aplying fix to kube-scheduler.yaml and kube-controller-manager.yaml \n"
  sed -i '/- --port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i '/- --port=0/d' /etc/kubernetes/manifests/kube-controller-manager.yaml
  printf "${BLUE} INFO ${NC} - RESTARTING KUBELET \n"
  systemctl restart kubelet
  sleep 5
  printf "${GREEN}FIXED${NC} Issue was resolved. Please hold.... \n"
  echo ""
fi


# Add Krew plugin for PV size
# Use with "kubectl df-pv"

echo "Deploying Krew plugin..."
curl https://krew.sh/df-pv | bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
printf "${GREEN}COMPLETE${NC} Krew Kubectl plugin deployed. You can now get PV size usage with "kubectl df-pv".\n"



printf "${BLUE}***************************************** ${NC} - Deployment completed! \n"
# Time to setup
printf "${PURPLE}COMPLETE${NC} Kubernetes cluster is almost ready to use. Setup completed in: \n"
ELAPSED="$((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
printf "Operation time: %s \n" $ELAPSED
sleep 2
echo ""
echo ""


printf "${BLUE}***************************************** ${NC} - Cleaning up the environment.. \n"
#************ CHECKS
# Clear all vars and screen
CONNECT_CHECK=""
PROXYDEFINED=""
pub_ip_outside=""
cansetup=""
clusterchecks_count=""
accessfailcount=""
clusterchecks_count=""
clusterchecks_success=""
clusterchecks_fail=""
clusterchecks_tracking=""
cansetup=""
CidrUserChoice=""
memoryonmachine=""
rootsizedisk=""
SECONDS=""
ELAPSED=""

echo ""
printf "${BLUE}***************************************** ${NC} - Waiting for cluster readyness (60 second hold).. \n"
echo""
secs=$((1 * 60)) # Countdown from 60 seconds, to give the cluster time to go up..
while [ $secs -gt 0 ]; do
   echo -ne "Time left $secs\033[0K seconds..\r"
   sleep 1
   : $((secs--))
done

printf "${PURPLE}COMPLETE${NC} Kubernetes cluster is now ready to use: \n"
echo ""
#Get all cluster info:
kubectl get all -A
echo ""
kubectl get cs
echo ""
kubectl df-pv
echo ""
echo ""