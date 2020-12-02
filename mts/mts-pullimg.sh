#!/bin/bash

# Authenticate into ECR
awspass=$(aws ecr get-login-password --region us-east-2)
docker login --username AWS --password $awspass 160256247964.dkr.ecr.us-east-2.amazonaws.com

# Pull EO images
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-core:1.0.3
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-kc-init:1.0.3
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-backend:1.0.3
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-frontend:1.0.3
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/grok_exporter:latest
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui:3.3.2
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui-plugin:3.3.2
