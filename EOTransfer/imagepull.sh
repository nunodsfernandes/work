# Upgrade script
# Set versions and exec script


EOVERSION="1.0.8"
SDVERSION="3.5.2"
GROKVERSION="latest"

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 160256247964.dkr.ecr.us-east-2.amazonaws.com

docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-core:$EOVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-kc-init:$EOVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-backend:$EOVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/eo-ui-frontend:$EOVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/grok_exporter:$GROKVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui:$SDVERSION
docker pull 160256247964.dkr.ecr.us-east-2.amazonaws.com/sd-ui-plugin:$SDVERSION

