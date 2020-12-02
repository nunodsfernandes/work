# !!!!!!!!!THIS IS ONGOING. DO NOT USE THE SCRIPT !!!!!!!!!!!!
# !!!!!!!!!THIS IS ONGOING. DO NOT USE THE SCRIPT !!!!!!!!!!!!
# !!!!!!!!!THIS IS ONGOING. DO NOT USE THE SCRIPT !!!!!!!!!!!!
# !!!!!!!!!THIS IS ONGOING. DO NOT USE THE SCRIPT !!!!!!!!!!!!

#!/bin/bash

# Update and install basics:
sudo yum update -y

sudo yum install -y qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer

sudo yum install bridge-utils -y

# Create a network bridge
cat <<EOF >  /etc/sysconfig/network-scripts/ifcfg-virbr0
DEVICE="virbr0"
BOOTPROTO="static"
IPADDR="192.168.12.10"
NETMASK="255.255.255.0"
GATEWAY="192.168.12.2"
DNS1=192.168.12.2
ONBOOT="yes"
TYPE="Bridge"
NM_CONTROLLED="no"
EOF

echo "BRIDGE=virbr0" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
