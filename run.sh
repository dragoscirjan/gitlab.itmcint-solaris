#! /bin/bash
set -xe 

PREFIX=solaris

apt-get update && apt-get install -y wget
which docker || wget -q -O - https://get.docker.com | bash

# https://docs.docker.com/registry/deploying/
docker ps -a | grep registry && {
  docker ps -a | grep registry | cut -f1 -d' ' | xargs docker stop || true
  docker ps -a | grep registry | cut -f1 -d' ' | xargs docker start || true
}

docker ps -a | grep registry || docker run -d -p 5000:5000 \
  --restart=always \
  --name registry -d registry:2


docker ps -a | grep jenkins && {
  docker ps -a | grep jenkins | cut -f1 -d' ' | xargs docker rm -f || echo
}

JENKINS_HOME="/vagrant/.run/jenkins"
if [ "$(hostname)" != "vagrant-base-xenial-amd64" ]; then
    JENKINS_HOME="/opt/solaris/.run/jenkins"
fi

mkdir -p $JENKINS_HOME/.ssh; 

[ -f $JENKINS_HOME/.ssh/id_rsa ] || ssh-keygen -b 2048 -t rsa -f $JENKINS_HOME/.ssh/id_rsa -q -N ""

chown -R 1000:1000 $JENKINS_HOME

# docker run \
docker run -p $((8000 + $(date +%d) + $(date +%m))):8080 \
  --restart=always \
  -e JENKINS_INSTALL_PLUGINS='simple-theme-plugin publish-over-ssh' \
  -v $JENKINS_HOME:/var/jenkins_home \
  -v /var/run/docker.sock:/run/docker.sock \
  --name jenkins -d qubestash/jenkins:latest

# docker ps -a | grep nginx && {
#   docker ps -a | grep nginx | cut -f1 -d' ' | xargs docker rm -f || echo
# }

# docker run -p 80:80 \
#   --restart=always \
#   -v /vagrant/proxy.conf:/etc/nginx/conf.d/proxy.conf \
#   --link jenkins:jenkins \
#   --name nginx -d nginx:alpine

sleep 10

docker stop jenkins
docker start jenkins

docker ps -a | grep $PREFIX-dind | xargs docker rm -f 

# TODO: Create our own or find a more "secure" image
docker run --privileged --name $PREFIX-dind -d benhall/dind-jenkins-agent