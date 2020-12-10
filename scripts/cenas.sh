#!/bin/bash

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-core:1.0.4

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-frontend:1.0.4

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-backend:1.0.4

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui:3.4.1

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui-plugin:3.4.1

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-kc-init:1.0.4

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/grok_exporter:latest

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
