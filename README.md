# Solaris Hosting Project

* [Notes](#notes)
* [Project Description](#project-description)
* [Server Operating System](#server-operating-system)
  * [Configure](#configure)
    * [sources.list](#sourceslist)
    * [mdadm.conf](#mdadmconf)
    * [Upgrade Kernel](#upgrade-kernel)
    * [SSH Key](#ssh-key)
    * [Port Forwarding](#port-forwarding)
  * [Prepare](#prepare)
    * [Utils](#utils)
    * [QubeStash](#qubestash)
    * [NFS](#nfs)
* [Standalone Containers](#)
  * [Varnish](#varnish) - Load Balancer & Cashing System
  * [Jenkins](#jenkins) - Continuous Integration

## Notes

```bash
# TERRA docker swarm init
docker swarm join \
    --token SWMTKN-1-0l198n162n0v758sl6jb0rq1o487b93wrn2fo5fyoypcs836oh-9e1pn0rn9hcx3j4c963dwschy \
    89.238.65.88:2377
```

## [Project Description](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc)

You can find the project description in the the following [link](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc). This document and repository, will only treat technical issues and running scripts.

## Server Operating System

### Configure

#### sources.list

```bash
deb http://mirror.manitu.net/ubuntu xenial main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-updates main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-security main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-backports main multiverse restricted universe
```

#### mdadm.conf

If Kernel RAID, check /etc/(mdadm/)mdadm.conf

> For more details, check http://www.ducea.com/2009/03/08/mdadm-cheat-sheet/

```bash

cat /etc/mdadm/mdadm.conf # this is Ubuntu, adapt path to own distro
mdadm --detail --scan

# if these two output differ, run:
mdadm --detail --scan >> /etc/mdadm.conf

```

#### Upgrade kernel

 to 4.4.0-57 or above

```
LINUX_VERSION=4.4.0-57 sh -c "apt-get install -y linux-image-\${LINUX_VERSION}-generic linux-image-extra-\${LINUX_VERSION}-generic"
```

#### SSH Key

> Use the public key to setup Jenkins SSH connection

```bash
ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
cat /root/.ssh/id_rsa.pub
```

#### Port Forwarding

> Enable port forwarding. You'll be using containers which will need it.

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

sed -e "s/.*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/g" -i /etc/sysctl.conf
sysctl -p
sysctl --system
```

> iptables rules are handled by jenkins now

* https://www.computersnyou.com/3047/forward-port-lxc-container-quick-tip/
* http://www.netfilter.org/documentation/HOWTO/NAT-HOWTO.txt
* https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables
* http://www.systutorials.com/816/port-forwarding-using-iptables/
* https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Security_Guide/s1-firewall-ipt-fwd.html
* https://www.cyberciti.biz/faq/how-to-iptables-delete-postrouting-rule/iptables-list-postrouting-rules/

### Prepare


#### Utils

```bash
apt-get install openssh-server git
```

#### QubeStash

```bash
wget -O - https://raw.githubusercontent.com/qubestash/stash/master/install-lxc.sh | bash
```

#### NFS

> This section is handled by [Solaris Hosting Service - NFS](doc/nfs-install.md) article.

## Standalone Containers

### Varnish

* https://komelin.com/articles/https-varnish
* https://www.digitalocean.com/community/tutorials/how-to-configure-varnish-cache-4-0-with-ssl-termination-on-ubuntu-14-04

# Running Jenkins & Registry

```bash
git clone https://gitlab.com/dragos.cirjan/solaris.git /opt/solaris
cd /opt/solaris
vagrant up --provider lxc

# add the following to /etc/crontab
# 0  0    * * *   root    bash /opt/solaris/run.sh
```

### Running Swarm

```bash
# Starting Master
QSTASH_CLUSTER=swarm QSTASH_NETWORK=10.0.3 QSTASH_PROVIDER=lxc vagrant up qstashmw1 --provider lxc
# Copy the generated token in the .token file
cat "..." > .token
# Starting Workers
for i in {2..3}; do QSTASH_MASTER_TOKEN=$(cat .token) QSTASH_CLUSTER=swarm QSTASH_NETWORK=10.0.3 \
    QSTASH_MASTER_IP=$(lxc-ls -f | grep 10 | awk -F' ' '{print $5}' | cut -f1 -d',') \
    QSTASH_PROVIDER=lxc vagrant up qstashmw$i --provider lxc; done
```

## Standalone Containers
### Varnish
### Jenkins

#### Connecting Jenkins to Docker

This [article](https://www.katacoda.com/courses/jenkins/build-docker-images) explains how to connect Docker with Jenkins.

Also, according to [this article](http://stackoverflow.com/a/43539359) 
(reffering this [issue](https://github.com/moby/moby/issues/25471)), on Ubuntu (16.04 LTS) with docker-ce (17.03.1~ce-0~ubuntu-xenial) do the following to make docker listen to a TCP port instead of sockets.

Add a file `/etc/systemd/system/docker.service.d/override.conf` with the following content:

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
```

Add a file `/etc/docker/daemon.json` with the following content

```json
{
    "hosts": [
        "tcp://127.0.0.1:2375",
        "tcp://127.17.0.1:2375"
    ] 
}
```

Reload (systemctl daemon-reload) and restart (systemctl restart docker.service) docker.