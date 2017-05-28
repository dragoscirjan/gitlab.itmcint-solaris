#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-nginx.local};
DOCKER_IMAGE=${DOCKER_IMAGE:-nginx:alpine};
DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-2};
DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx};

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx};

mkdir -p $NGINX_HOME;

#
# remove directive
#
if echo $* | grep "remove"; then
    # nginx::remove
    abstract::web::remove
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

#
# create/update
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
    # nginx::update
    abstract::web::update
else
    nginx::create
fi

sleep 20;

nginx::info