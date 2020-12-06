#!/bin/bash

#Start Minikube with "none" as driver
sudo minikube start --driver=none

# Certificate management
sudo mv /root/.kube /root/.minikube $HOME
sudo chown -R $USER $HOME/.kube $HOME/.minikube
sudo chmod -R 444 $HOME/.minikube/profiles/minikube/client.key
sudo chmod -R 444 $HOME/.minikube/profiles/minikube/client.crt
sudo chmod -R 444 /home/centos/.minikube/ca.crt

# Edit the configuration. A backup file will be kept (~/.kube/config_backup)
cp ~/.kube/config ~/.kube/config_backup
sed 's+root+home/centos+g' ~/.kube/config > ~/.kube/config_fix
cp ~/.kube/config_fix ~/.kube/config
rm ~/.kube/config_fix

clear
echo ""
echo "Part 2 of the setup is finished."
echo ""
echo "Please run the command "aws configure" now and authenticate yourself on the AWS CLI using the provided credentials."
echo ""
echo "After you finish the authentication, please run part 3 of the script using the following command:"
echo "curl -fsSL https://raw.githubusercontent.com/nunodsfernandes/work/master/minikube/minikube3.sh | sh"
echo ""
