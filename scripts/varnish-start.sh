set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

export DOCKER_SERVICE_NAME="global_varnish-cache";
export DOCKER_HOSTNAME="varnish.local";

export DOCKER_LOG_OPTIONS="--log-driver json-file --log-opt max-size=10m --log-opt max-file=3";
export DOCKER_IMAGE="qubestash/varnish-cache:alpine";
export DOCKER_REPLICAS=1;

# export VCL_BACKEND_ADDRESS=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -a | grep global_nginx\. | cut -f1 -d' ')`

VARNISH_HOME=/data/http/varnish

mkdir -p $VARNISH_HOME
bash $HERE/config.vcl.sh > $VARNISH_HOME/config.vcl

# docker service rm $DOCKER_SERVICE_NAME || true

if docker service ls | grep $DOCKER_SERVICE_NAME; then
    docker service update \
        --image $DOCKER_IMAGE \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_SERVICE_NAME;
else
    docker service create \
        $DOCKER_LOG_OPTIONS \
        --replicas $DOCKER_REPLICAS \
        --hostname $DOCKER_HOSTNAME \
        --env VCL_USE_CONFIG=yes \
        --mount type=mount,source=$VARNISH_HOME/config.vcl;destination=/etc/varnish/default.vcl \
        --publish 80:80 \
        --name $DOCKER_SERVICE_NAME $DOCKER_IMAGE;
fi;

sleep 20;

docker service ls;
docker service inspect --pretty $DOCKER_SERVICE_NAME;
docker service ps $DOCKER_SERVICE_NAME;