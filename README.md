# Solaris Hosting Project

* [Project Description](#project-description)
* [Standalone Containers](#)
  * [Varnish](#varnish) - Load Balancer & Cashing System
  * [Jenkins](#jenkins) - Continuous Integration

## [Project Description](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc)

You can find the project description in the the following [link](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc). This document and repository, will only treat technical issues and running scripts.

### Preparing

#### Configure /etc/apt/sources.list

```bash
deb http://mirror.manitu.net/ubuntu xenial main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-updates main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-security main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-backports main multiverse restricted universe
```

#### Installing Util tools

```bash
apt-get install openssh-server
```

#### Installing QubeStash


#### Preparing for Jenkins

> Use the public key to setup Jenkins SSH connection

```bash
ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
cat /root/.ssh/id_rsa.pub
```

## Standalone Containers

### Varnish

### Jenkins

#### Preparing

```
groupadd jenkins
useradd jenkins -g jenkins -d /home/jenkins
mkdir /home/jenkins
chown -R jenkins:jenkins /home/jenkins

sudo -H -u jenkins bash -c 'mkdir -p /home/jenkins/.ssh; ssh-keygen -b 2048 -t rsa -f /home/jenkins/.ssh/id_rsa -q -N ""'
cat /home/jenkins/.ssh/id_rsa.pub
```

#### Running

```bash
docker run --name jenkins --restart always \
    -p $((8000 + $(date +%d))):8080 \
    -e JENKINS_INSTALL_PLUGINS='simple-theme-plugin publish-over-ssh'
    -v /home/jenkins:/var/jenkins_home \
    -d qubestash/jenkins:latest 
```