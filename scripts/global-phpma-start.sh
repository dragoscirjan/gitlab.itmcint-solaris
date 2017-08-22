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

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_pma};
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-mysql.local};

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_IMAGE=${DOCKER_IMAGE:-phpmyadmin/phpmyadmin:latest};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1};

MYSQL_HOME=${MYSQL_HOME:-$HERE/data/sql}
MYSQL_LIB_HOME=${MYSQL_LIB_HOME:-$HERE/data/mysql}

mkdir -p $MYSQL_HOME $MYSQL_LIB_HOME;

export MYSQL_ROOT_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1);

#
# remove directive
#
if echo $* | grep "remove"; then
    docker service rm $DOCKER_SERVICE_NAME
fi

#
# stop if re-run
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
  echo "Container $DOCKER_SERVICE_NAME already exists!";
  docker ps -a | grep $DOCKER_SERVICE_NAME | xargs docker rm -f
  # docker service update \
  #       $ENV_UPDATE \
  #       --image $DOCKER_IMAGE \
  #       --publish-add 3306:3306 \
  #       $DOCKER_ADDITIONAL_UPDATE \
  #       $DOCKER_SERVICE_NAME;
  exit 0;
fi;

#
# create
#
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
echo "+ MYSQL ROOT PASS $MYSQL_ROOT_PASSWORD ";
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";

MYSQL_DOCKER_INSTANCE=$(docker ps -a | egrep -v "Exited|Greated" | grep global_mysql | awk -F' ' '{ print $NF }')
docker run --name $DOCKER_SERVICE_NAME -d --link $MYSQL_DOCKER_INSTANCE:db -p 8080:8080 $DOCKER_IMAGE

# docker service create $DOCKER_LOG_OPTIONS --mode global \
#     --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
#     --hostname $DOCKER_HOSTNAME \
#     --mount type=bind,source=$MYSQL_HOME,destination=/sql \
#     --mount type=bind,source=$MYSQL_LIB_HOME,destination=/var/lib/mysql \
#     --network web-network \
#     --publish 3306:3306 \
#     $DOCKER_ADDITIONAL_START \
#     --name $DOCKER_SERVICE_NAME $DOCKER_IMAGE

sleep 20;

# docker service ls;
# docker service inspect --pretty $DOCKER_SERVICE_NAME;
docker service ps $DOCKER_SERVICE_NAME;