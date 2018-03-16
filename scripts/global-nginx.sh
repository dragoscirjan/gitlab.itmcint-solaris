#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-nginx.local};
DOCKER_IMAGE=${DOCKER_IMAGE:-nginx:alpine};
DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1};
DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx};
# DOCKER_ADDITIONAL_CREATE="--publish 80:80";

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx};

docker service rm $DOCKER_SERVICE_NAME || true

sleep 10

docker pull $DOCKER_IMAGE

docker service create \
  --hostname $DOCKER_HOSTNAME \
  --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
  --name $DOCKER_SERVICE_NAME \
  --network web-network \
  --replicas $DOCKER_REPLICAS \
  $DOCKER_LOG_OPTIONS \
  $DOCKER_ADDITIONAL_CREATE \
  $DOCKER_IMAGE;
  
sleep 5

docker service ls

docker service inspect $DOCKER_SERVICE_NAME
