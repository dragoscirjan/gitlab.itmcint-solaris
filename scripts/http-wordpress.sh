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

DOCKER_CODEX_IMAGE=${DOCKER_CODEX_IMAGE:-qubestash/wordpress:fpm-alpine}

# WORDPRESS_DOMAIN_PROTO=${WORDPRESS_DOMAIN_PROTO:-https}
WORDPRESS_MYSQL_DB=${WORDPRESS_MYSQL_DB:-database}
WORDPRESS_MYSQL_USER=${WORDPRESS_MYSQL_USER:-user}
WORDPRESS_MYSQL_PASS=${WORDPRESS_MYSQL_PASS:-pass}
WORDPRESS_MYSQL_HOST=${WORDPRESS_MYSQL_HOST:-global_mysql}
WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX:-wp}
# WORDPRESS_PLUGINS=${WORDPRESS_PLUGINS:-};

bash $HERE/http-html.sh

docker service rm $APPLICATION_CODEX_NAME || true

docker volume rm $APPLICATION_CODEX_NAME || true

sleep 5

# pull image
docker pull $DOCKER_CODEX_IMAGE

# create volume
docker volume create --name $APPLICATION_CODEX_NAME

mkdir -p $APPLICATION_HOME/wp-content/plugins $APPLICATION_HOME/wp-content/themes $APPLICATION_HOME/wp-content/uploads

# create service
soureWPContent=$APPLICATION_HOME/wp-content
destiWpContent=/usr/src/wordpress
docker service create \
    --env WORDPRESS_DOMAIN_PROTO=$WORDPRESS_DOMAIN_PROTO \
    --env WORDPRESS_MYSQL_DB=$WORDPRESS_MYSQL_DB \
    --env WORDPRESS_MYSQL_USER=$WORDPRESS_MYSQL_USER \
    --env WORDPRESS_MYSQL_PASS=$WORDPRESS_MYSQL_PASS \
    --env WORDPRESS_MYSQL_HOST=$WORDPRESS_MYSQL_HOST \
    --env WORDPRESS_TABLE_PREFIX=$WORDPRESS_TABLE_PREFIX \
    --env WORDPRESS_PLUGINS="$WORDPRESS_PLUGINS" \
    --env SQL_1="mysql -u$WORDPRESS_MYSQL_USER -p$WORDPRESS_MYSQL_PASS -h$WORDPRESS_MYSQL_HOST" \
    --env SQL_2="CREATE USER IF NOT EXISTS $WORDPRESS_MYSQL_USER@'%' IDENTIFIED BY '$WORDPRESS_MYSQL_PASS'" \
    --env SQL_3="CREATE DATABASE IF NOT EXISTS $WORDPRESS_MYSQL_DB" \
    --env SQL_4="GRANT ALL PRIVILEGES ON $WORDPRESS_MYSQL_DB.* TO '$WORDPRESS_MYSQL_USER'@'%'" \
    --env SQL_5="ALTER USER $WORDPRESS_MYSQL_USER@'%' IDENTIFIED BY '$WORDPRESS_MYSQL_PASS' " \
    --hostname $APPLICATION_CODEX_NAME \
    --name $APPLICATION_CODEX_NAME \
    --network web-network \
    --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
    --mount type=bind,source=/etc/localtime,destination=/etc/localtime \
    --mount type=volume,source=$APPLICATION_CODEX_NAME,destination=$destiWpContent \
    --mount type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
    --mount type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
    --replicas $DOCKER_CODEX_REPLICAS \
    $DOCKER_LOG_OPTIONS \
    $DOCKER_ADDITIONAL_CREATE \
    $DOCKER_CODEX_IMAGE

sleep 5 

docker service ls
docker service inspect --pretty $APPLICATION_CODEX_NAME
docker service ps $APPLICATION_CODEX_NAME
docker ps -a | grep $APPLICATION_CODEX_NAME

# determine whether php-fpm was loaded properly, or wait for it ...
while [ "$(php-fpm::test-running $APPLICATION_CODEX_NAME)" != "0" ]; do
    echo "Waiting for Wordpress & php-fpm to start";
    sleep 10
done

# configure application config
cat $HERE/http-wordpress.conf \
    | sed -e "s/domain.local/$APPLICATION_TLD/g" \
    | sed -e "s/php.local/$APPLICATION_CODEX_NAME/g" \
    | sed -e "s|__ROOT__|/usr/src/wordpress|g" \
    > $NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf

# update nginx

docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    --mount-rm /etc/nginx/conf.d/$APPLICATION_TLD_SSL.conf \
    --mount-rm $destiWpContent/wp-content/uploads \
    --mount-rm $destiWpContent/wp-content/themes \
    --mount-rm $destiWpContent \
    $APPLICATION_NGINX_NAME

sleep 5

docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    --mount-add /etc/nginx/conf.d/$APPLICATION_TLD_SSL.conf \
    --mount-add type=bind,source=$NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf,destination=/etc/nginx/conf.d/$APPLICATION_TLD_SSL.conf \
    --mount-add type=volume,source=$APPLICATION_CODEX_NAME,destination=$destiWpContent \
    --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
    --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
    $APPLICATION_NGINX_NAME

# bash $HERE/global-nginx-proxy.sh
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    $NGINX_PROXY_NAME




# DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-wordpress}
# DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-wordpress.local}

# DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3}
# 
# DOCKER_REPLICAS=${DOCKER_REPLICAS:-1}

# MYSQL_HOME=${MYSQL_HOME:-$HERE/mysql}
# MYSQL_LIB_HOME=${MYSQL_LIB_HOME:-$HERE/mysql/lib}

# APPLICATION_TLD=${APPLICATION_TLD:-wordpress.local}

# docker-ip() {
#     docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
#         $(docker ps -a | grep $DOCKER_SERVICE_NAME\. | cut -f1 -d' ');
# }

# APPLICATION_HOME=${APPLICATION_HOME:-$HERE/data/sites/$DOCKER_HOSTNAME}

# NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx}
# NGINX_CONF=${NGINX_CONF:-http-wordpress.conf}
# NGINX_HOME_PROXY=${NGINX_HOME_PROXY:-$HERE/data/http/nginx-proxy}



# #
# # remove directive
# #
# if echo $* | grep "remove"; then
#     wordpress::remove
# fi
# if echo $* | grep "remove-only"; then
#     exit 0
# fi

# #
# # create / update
# #
# if docker service ls | grep $DOCKER_SERVICE_NAME; then
#     wordpress::update
# else
#     wordpress::create
# fi;

# sleep 20

# docker service ls
# docker service inspect --pretty $DOCKER_SERVICE_NAME
# docker service ps $DOCKER_SERVICE_NAME

# # sleep 20

# # docker service ls
# # docker service inspect --pretty $DOCKER_SERVICE_NAME
# # docker service inspect --pretty global_nginx
# # docker service ps $DOCKER_SERVICE_NAME
# # docker service ps global_nginx