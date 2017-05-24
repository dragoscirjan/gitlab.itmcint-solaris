#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx};
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-nginx.local};

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_IMAGE=${DOCKER_IMAGE:-nginx:alpine};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-2};

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx};

#
#
#

mkdir -p $NGINX_HOME;

echo "$@" | grep --rm && docker service rm $DOCKER_SERVICE_NAME || true

if docker service ls | grep $DOCKER_SERVICE_NAME; then
    docker service update \
        --image $DOCKER_IMAGE \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_SERVICE_NAME;
else
    # DOCKER_ADDITIONAL_START="--publish 80:80";
    docker service create \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_START \
        --replicas $DOCKER_REPLICAS \
        --hostname $DOCKER_HOSTNAME \
        --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
        --name $DOCKER_SERVICE_NAME $DOCKER_IMAGE;
fi

sleep 20;

docker service ls;
docker service inspect --pretty $DOCKER_SERVICE_NAME;
docker service ps $DOCKER_SERVICE_NAME;