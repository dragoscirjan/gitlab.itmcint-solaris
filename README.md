# Solaris Hosting Project

* [Project Description](#project-description)
* [Standalone Containers](#)
  * [Varnish](#varnish) - Load Balancer & Cashing System
  * [Jenkins](#jenkins) - Continuous Integration

## [Project Description](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc)

You can find the project description in the the following [link](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc). This document and repository, will only treat technical issues and running scripts.

## Standalone Containers

### Varnish

### Jenkins

#### Preparing

```
groupadd jenkins
useradd jenkins -g jenkins -d /home/jenkins
mkdir /home/jenkins
chown -R jenkins:jenkins /home/jenkins

mkdir -p /home/jenkins/.ssh
chown -R jenkins:jenkins /home/jenkins
sudo -H -u jenkkins bash -c 'ssh-keygen -b 2048 -t rsa -f /home/jenkins/.ssh/id_rsa -q -N ""'
cat /home/jenkins/.ssh/id_rsa.pub
```

#### Running

```bash
docker run --name jenkins --restart always \
    -p $((8000 + $(date +%d))):8080 \
    -v /home/jenkins:/var/jenkins_home \
    -d qubestash/jenkins:latest 
```