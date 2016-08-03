#! /bin/bash

DOCKER_USER=vagrant
[ "$1" != "" ] && DOCKER_USER=$1

echo '----------------------------------------------------'
echo '- Installing Dependencies'
echo '----------------------------------------------------'

which apt-get > /dev/null && {
  apt-get update -y
  # add-apt-repository
  apt-get install python-software-properties apt-transport-https ca-certificates -y
  # Docker Respository
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  ( lsb_release -a 2> /dev/null | grep Ubuntu > /dev/null ) && {
    echo "deb https://apt.dockerproject.org/repo ubuntu-`( lsb_release -a 2> /dev/null | grep Ubuntu > /dev/null ) && ( lsb_release -a 2> /dev/null | grep Codename | awk -F ' ' '{ print $2 }' | tail -n 1 )` main" > /etc/apt/sources.list.d/docker.list
  } || {
    echo "deb https://apt.dockerproject.org/repo debian-`( lsb_release -a 2> /dev/null | grep Ubuntu > /dev/null ) && ( lsb_release -a 2> /dev/null | grep Codename | awk -F ' ' '{ print $2 }' | tail -n 1 )` main" > /etc/apt/sources.list.d/docker.list
  }
  # Java Repository
  add-apt-repository ppa:webupd8team/java -y
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections

  apt-get update -y
  apt-cache policy docker-engine
  apt-get purge lxc-docker -y
  ( lsb_release -a 2> /dev/null | grep Ubuntu > /dev/null ) && apt-get install linux-image-extra-$(uname -r) -y
  apt-get install \
    lxc docker-engine \
    oracle-java8-installer \
    unzip wget \
    -y
}

which yum && {
  echo 'this is a @todo'
}

usermod -aG docker $DOCKER_USER

echo '----------------------------------------------------'
echo '- Installing CHE nightly'
echo '----------------------------------------------------'

wget -q https://install.codenvycorp.com/che/eclipse-che-nightly.zip
unzip eclipse-che-nightly.zip -d eclipse-che-nightly
chown -R $DOCKER_USER:$DOCKER_USER eclipse-che-nightly

echo '----------------------------------------------------'
echo '- Installing CHE stable'
echo '----------------------------------------------------'

wget -q https://install.codenvycorp.com/che/eclipse-che-latest.zip
unzip eclipse-che-latest.zip -d eclipse-che-latest
chown -R $DOCKER_USER:$DOCKER_USER eclipse-che-latest

# HTTP_PROXY=$1
# HTTPS_PROXY=$2
# CHE_VERSION=$3
# IP=$4
# if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
#   echo "-----------------------------------"
#   echo "."
#   echo "ARTIK IDE: CONFIGURING SYSTEM PROXY"
#   echo "."
#   echo "-----------------------------------"
#   echo 'export HTTP_PROXY="'$HTTP_PROXY'"' >> /home/vagrant/.bashrc
#   echo 'export HTTPS_PROXY="'$HTTPS_PROXY'"' >> /home/vagrant/.bashrc
#   source /home/vagrant/.bashrc
#   echo "HTTP PROXY set to: $HTTP_PROXY"
#   echo "HTTPS PROXY set to: $HTTPS_PROXY"
# fi
# # Add the user in the VM to the docker group
# usermod -aG docker vagrant &>/dev/null
# # Configure Docker daemon with the proxy
# if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
#     mkdir /etc/systemd/system/docker.service.d
# fi
# if [ -n "$HTTP_PROXY" ]; then
#     printf "[Service]\nEnvironment=\"HTTP_PROXY=${HTTP_PROXY}\"" > /etc/systemd/system/docker.service.d/http-proxy.conf
# fi
# if [ -n "$HTTPS_PROXY" ]; then
#     printf "[Service]\nEnvironment=\"HTTPS_PROXY=${HTTPS_PROXY}\"" > /etc/systemd/system/docker.service.d/https-proxy.conf
# fi
# if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
#     printf "[Service]\nEnvironment=\"NO_PROXY=localhost,127.0.0.1\"" > /etc/systemd/system/docker.service.d/no-proxy.conf
#     systemctl daemon-reload
#     systemctl restart docker
# fi
# echo "--------------------------------"
# echo "."
# echo "ARTIK IDE: DOWNLOADING ARTIK IDE"
# echo "."
# echo "--------------------------------"
# curl -O "https://install.codenvycorp.com/artik/samsung-artik-ide-${CHE_VERSION}.tar.gz"
# tar xvfz samsung-artik-ide-${CHE_VERSION}.tar.gz &>/dev/null
# sudo chown -R vagrant:vagrant * &>/dev/null
# export JAVA_HOME=/usr &>/dev/null
# # exporting CHE_LOCAL_CONF_DIR, reconfiguring Che to store workspaces, projects and prefs outside the Tomcat
# export CHE_LOCAL_CONF_DIR=/home/vagrant/.che &>/dev/null
# cp /home/vagrant/eclipse-che-*/conf/che.properties /home/vagrant/.che/
# sed -i 's|${catalina.base}/temp/local-storage|/home/vagrant/.che|' /home/vagrant/.che/che.properties
# sed -i 's|${che.home}/workspaces|/home/vagrant/.che|' /home/vagrant/.che/che.properties
# echo 'export CHE_LOCAL_CONF_DIR=/home/vagrant/.che' >> /home/vagrant/.bashrc
# echo "------------------------------------------"
# echo "."
# echo "ARTIK IDE: DOWNLOADING ARTIK RUNTIME IMAGE"
# echo "           950MB: SILENT OUTPUT           "
# echo "."
# echo "------------------------------------------"
# docker pull codenvy/artik &>/dev/null
# echo "--------------------------------------"
# echo "."
# echo "ARTIK IDE: DOWNLOADING DOCKER REGISTRY"
# echo "           50MB: SILENT OUTPUT        "
# echo "."
# echo "--------------------------------------"
# docker pull registry:2 &>/dev/null
# echo "-------------------------------"
# echo "."
# echo "ARTIK IDE: PREPPING SERVER ~10s"
# echo "."
# echo "-------------------------------"
# if [ -n "$HTTP_PROXY" ]; then
#     sed -i "s|http.proxy=|http.proxy=${HTTP_PROXY}|" /home/vagrant/eclipse-che-*/conf/che.properties
# fi
# if [ -n "$HTTPS_PROXY" ]; then
#     sed -i "s|https.proxy=|https.proxy=${HTTPS_PROXY}|"  /home/vagrant/eclipse-che-*/conf/che.properties
# fi
# echo vagrant | sudo -S -E -u vagrant /home/vagrant/eclipse-che-*/bin/che.sh --remote:${IP} --skip:client -g start &>/dev/null
