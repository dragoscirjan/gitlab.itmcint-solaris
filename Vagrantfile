# -*- mode: ruby -*-
# vi: set ft=ruby :

# Supporting LXC, Virtualbox and Libvirt (KVM/Qemu)
#
# Boxes:
# @link https://github.com/boxcutter (for Virtualbox images)
# @link https://github.com/dragosc (for LXC images)
#
# Plugins:
# @link https://github.com/fgrehm/vagrant-lxc
# @link https://github.com/pradels/vagrant-libvirt#create-box (for Libvirt images)
# @link https://github.com/sciurus/vagrant-mutate

Vagrant.configure(2) do |config|

  config.vm.define :ubuntu do |ubuntu|
    # --provider lxc
    ubuntu.vm.provider :lxc do |lxc, override|
      lxc.customize "network.ipv4", "10.0.3.101/24"
      override.vm.box = "dragosc/trusty64"
    end

    # --provider virtualbox
    ubuntu.vm.provider :virtualbox do |virtualbox, override|
      override.vm.network "private_network", ip: "192.168.50.101"
      override.vm.box = "ubuntu/xenial64" # 16.04
    end
  end

  config.vm.provision :shell, inline: <<DOCKER_SCRIPT
set -xe 

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

mkdir -p /vagrant/.run/jenkins
chown -R ubuntu:ubuntu /vagrant/.run/jenkins

#sudo -H -u jenkins bash -c 'mkdir -p /home/jenkins/.ssh; ssh-keygen -b 2048 -t rsa -f /home/jenkins/.ssh/id_rsa -q -N ""'
#cat /home/jenkins/.ssh/id_rsa.pub

docker ps -a | grep jenkins && {
  docker ps -a | grep registry | cut -f1 -d' ' | xargs docker rm -f
}
docker run -p \$((8000 + \$(date +%d))):8080 \
  --restart=always \
  -e JENKINS_INSTALL_PLUGINS='simple-theme-plugin publish-over-ssh' \
  -v /vagrant/.run/jenkins:/var/jenkins_home \
  --name jenkins -d qubestash/jenkins:latest

DOCKER_SCRIPT

end
