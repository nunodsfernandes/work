Create files on the VM with the following:

```
vi minikube1.sh
```

Contents:

```
sudo yum update -y
sudo yum install -y conntrack
sudo yum install unzip -y
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/
sudo mv /usr/local/bin/minikube /usr/bin/
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $(whoami)
sudo systemctl start docker
sudo systemctl enable docker
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add couchdb https://apache.github.io/couchdb-helm
helm repo update
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo mkdir /usr/share/
sudo mkdir /usr/share/filebeat
sudo mkdir /var/lib/
sudo mkdir /var/lib/filebeat-data
sudo chmod -R 777 /usr/share/filebeat
sudo chmod -R 777 /var/lib/filebeat-data
```

--------------------

```
vi minikube2.sh
```

Contents:

```
sudo minikube start --driver=none
sudo mv /root/.kube /root/.minikube $HOME
sudo chown -R $USER $HOME/.kube $HOME/.minikube
sudo chmod -R 444 $HOME/.minikube/profiles/minikube/client.key
sudo chmod -R 444 $HOME/.minikube/profiles/minikube/client.crt
sudo chmod -R 444 /home/centos/.minikube/ca.crt
sudo cp ~/.kube/config ~/.kube/config_backup
sudo sed 's+root+home/centos+g' ~/.kube/config > ~/.kube/config_fix
sudo cp ~/.kube/config_fix ~/.kube/config
sudo rm ~/.kube/config_fix
```


-------


```
vi minikube3.sh
```

Contents: 

```
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-core:1.0.3

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-frontend:1.0.3

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-backend:1.0.3

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui:3.4.0

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui-plugin:3.4.0

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-kc-init:1.0.3

clear
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/grok_exporter:latest

kubectl create namespace eo
kubectl create namespace monitoring
sudo mkdir eo-install
cd eo-install

clear

echo " *********** These are the docker images pulled from ECR:"
echo ""
docker images | grep amazonaws
echo ""
echo ""
echo " *********** These are the pods running on the Minikube setup:"
kubectl get pods --all-namespaces
echo ""
echo ""
echo "Your instance should now be ready for the Helm Chart deployment."
echo "Refer to the SaaS Ops GitHub page for further instructions!"
echo ""
echo "Thank you."
echo ""
```


***



### Make the files executable
```
sudo chmod +x minikube1.sh minikube2.sh minikube3.sh 
```


### Run the first file with:
 
```
./minikube1.sh
```

### Restart session
Restart session to re-evaluate Docker permissions to your user.
```
exit
```
Login again.


### Run the second file with:

```
./minikube2.sh
```

### Configure AWS
```
aws configure
```

### Authenticate to ECR and download images with:

```
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 160256247964.dkr.ecr.us-east-2.amazonaws.com
```

### Run the third file with:

```
./minikube3.sh
```


