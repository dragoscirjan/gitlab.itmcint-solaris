#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-nginx-proxy.local};
# DOCKER_IMAGE=${DOCKER_IMAGE:-qubestash/nginx:alpine}; qubestash/nginx is discontinued
DOCKER_IMAGE=${DOCKER_IMAGE:-nginx:alpine};
DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1};
DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx-proxy};

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx-proxy};
NGINX_HOME_CERTBOT=${NGINX_HOME_CERTBOT:-$HERE/data/certbot};
NGINX_HOME_QUBE=${NGINX_HOME_QUBE:-$HERE/data/qubestash};
NGINX_HOME_SSL=${NGINX_HOME_SSL:-$HERE/data/http/ssl};

###

mkdir -p $NGINX_HOME $NGINX_HOME_SSL $NGINX_HOME_QUBE $NGINX_HOME_CERTBOT;

if echo $* | grep "dev"; then
	export DOCKER_ADDITIONAL_CREATE=" \
		$DOCKER_ADDITIONAL_CREATE \
		--mount type=bind,source=/home/dragosc/Workspace/QubeStash/http-nginx/scripts/nginx-certbot,destination=/nginx-certbot \
		--env NGINX_DEBUG=no \
	"
fi

docker service rm $APPLICATION_NGINX_PROXY_NAME || true

sleep 5

# pull image
docker pull $DOCKER_IMAGE

# generate ssl
openssl req -subj '/CN=qubestash.org/O=QubeStash ORG./C=RO' \
    -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $NGINX_HOME_SSL/qubestash.key \
    -out $NGINX_HOME_SSL/qubestash.crt

# DOCKER_ADDITIONAL_CREATE="--publish 80:80";
docker service create \
    --env NGINX_CERTBOT_EMAIL="office@itmediaconnect.ro" \
    --hostname $DOCKER_HOSTNAME \
    --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
    --mount type=bind,source=$NGINX_HOME_CERTBOT,destination=/etc/letsencrypt \
    --mount type=bind,source=$NGINX_HOME_QUBE,destination=/var/qubestash \
    --mount type=bind,source=$NGINX_HOME_SSL,destination=/etc/nginx/ssl \
    --name $APPLICATION_NGINX_PROXY_NAME \
    --network web-network \
    --replicas $DOCKER_REPLICAS \
    $DOCKER_LOG_OPTIONS \
    $DOCKER_ADDITIONAL_CREATE \
    $DOCKER_IMAGE;

sleep 5;

docker service ls | egrep "$APPLICATION_NGINX_PROXY_NAME"
docker service inspect --pretty $APPLICATION_NGINX_PROXY_NAME;
docker service ps $APPLICATION_NGINX_PROXY_NAME;
docker ps -a | grep -v Exited | egrep "$APPLICATION_NGINX_PROXY_NAME\.[0-9]+"
docker ps -a | grep Exited | egrep "$APPLICATION_NGINX_PROXY_NAME\.[0-9]+" || true