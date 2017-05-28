#! /bin/sh
set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_varnish-cache};
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-varnish.local};

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_IMAGE=${DOCKER_IMAGE:-qubestash/varnish-cache:alpine};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1};

# export VCL_BACKEND_ADDRESS=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -a | grep global_nginx\. | cut -f1 -d' ')`

VARNISH_HOME=${VARNISH_HOME:-$HERE/data/http/varnish}

mkdir -p $VARNISH_HOME

if echo $* | grep "remove"; then
    # remove instance
    varnish::remove
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

if docker service ls | grep $DOCKER_SERVICE_NAME; then
    # update instance
    varnish::update
else
    # create instance
    varnish::create
fi;

sleep 20;

# info instance
varnish::info