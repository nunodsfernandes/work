# Intelligent Edge Provisioning

# Remove the config file if it exists (test purpose, remove after)
rm remoteconfig.conf

# Create new conf file
echo  " " > remoteconfig.conf
# Gather basic info and build file
echo "" >> remoteconfig.conf
echo " ******************************** " >> remoteconfig.conf
echo " *   Edge Device Basic Config   * " >> remoteconfig.conf
echo " ******************************** " >> remoteconfig.conf
echo "" >> remoteconfig.conf
echo "" >> remoteconfig.conf
echo "Username (system):    " $(whoami) >> remoteconfig.conf #Will need to change this to add a user to the kubernetes cluster with permissions
echo "Network Internal IP:  " $(ip a | grep "scope global dynamic" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{if(NR<2)print}') >> remoteconfig.conf
echo "Network Public IP:    " $(curl https://ipecho.net/plain) >> remoteconfig.conf
echo "Total Machine Memory: " $(grep VmallocTotal /proc/meminfo | sed 's/:[[:blank:]]*/: /' | tr -d "VmallocTotal: " | awk '{$1/=1024;printf "%.2fMB\n",$1}')
echo "Total Machine CPU(s): " $(lscpu | grep "CPU(s):" | sed 's/:[[:blank:]]*/: /' | tr -d "CPU(s):" | awk '{if(NR<2)print}') >> remoteconfig.conf
echo "" >> remoteconfig.conf
echo "" >> remoteconfig.conf
# Show the remoteconfig
clear
cat remoteconfig.conf

# Send the configuration to the server
