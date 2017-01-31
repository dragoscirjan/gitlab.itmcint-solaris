# Solaris Hosting Project

* [Project Description](#project-description)
* [Server Operating System](#server-operating-system) - prepare and config
* [Standalone Containers](#)
  * [Varnish](#varnish) - Load Balancer & Cashing System
  * [Jenkins](#jenkins) - Continuous Integration

## [Project Description](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc)

You can find the project description in the the following [link](https://docs.google.com/document/d/1yIL9FuCW8ZtKg7DTPA2h2rI-LjoQJx7LS-whFkSfJkc). This document and repository, will only treat technical issues and running scripts.

## Server Operating System

### Prepare

#### Configure /etc/apt/sources.list

```bash
deb http://mirror.manitu.net/ubuntu xenial main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-updates main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-security main multiverse restricted universe
deb http://mirror.manitu.net/ubuntu xenial-backports main multiverse restricted universe
```

#### If Kernel RAID, check /etc/(mdadm/)mdadm.conf

> For more details, check http://www.ducea.com/2009/03/08/mdadm-cheat-sheet/

```bash

cat /etc/mdadm/mdadm.conf # this is Ubuntu, adapt path to own distro
mdadm --detail --scan

# if these two output differ, run:
mdadm --detail --scan >> /etc/mdadm.conf

```

#### Upgrade kernel to 4.4.0-57 or above

```
LINUX_VERSION=4.4.0-57 sh -c "apt-get install -y linux-image-\${LINUX_VERSION}-generic"
```

#### Install Some Util Tools

```bash
apt-get install openssh-server git
```

#### Install QubeStash

```bash
wget -O - https://raw.githubusercontent.com/qubestash/stash/master/install-lxc.sh | bash
```

#### Preparing for Jenkins

> Use the public key to setup Jenkins SSH connection

```bash
ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
cat /root/.ssh/id_rsa.pub
```

### iptables (Port Forwarding)

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

sed -e "s/.*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/g" -i /etc/sysctl.conf
sysctl -p
sysctl --system

# port forwarding port 80 to swarm master
export IF=ifext; \
	export TO_80=$(lxc-ls -f | grep qstashm | awk -F' ' '{print $5}' | cut -f1 -d','); \
	iptables -t nat -D PREROUTING -i $IF -p tcp --dport 80 -j DNAT --to $TO_80:80 || true; \
	iptables -t nat -A PREROUTING -i $IF -p tcp --dport 80 -j DNAT --to $TO_80:80; \
    iptables -t nat -nL;

```

* https://www.computersnyou.com/3047/forward-port-lxc-container-quick-tip/
* http://www.netfilter.org/documentation/HOWTO/NAT-HOWTO.txt
* https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables
* http://www.systutorials.com/816/port-forwarding-using-iptables/
* https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Security_Guide/s1-firewall-ipt-fwd.html
* https://www.cyberciti.biz/faq/how-to-iptables-delete-postrouting-rule/iptables-list-postrouting-rules/

## Standalone Containers

### Varnish

* https://komelin.com/articles/https-varnish
* https://www.digitalocean.com/community/tutorials/how-to-configure-varnish-cache-4-0-with-ssl-termination-on-ubuntu-14-04

### Jenkins

#### Preparing

```
groupadd jenkins
useradd jenkins -g jenkins -d /home/jenkins
mkdir /home/jenkins
chown -R jenkins:jenkins /home/jenkins

#sudo -H -u jenkins bash -c 'mkdir -p /home/jenkins/.ssh; ssh-keygen -b 2048 -t rsa -f /home/jenkins/.ssh/id_rsa -q -N ""'
#cat /home/jenkins/.ssh/id_rsa.pub
```

#### Running

```bash
docker run --name jenkins --restart always \
    -p $((8000 + $(date +%d))):8080 \
    -e JENKINS_INSTALL_PLUGINS='simple-theme-plugin publish-over-ssh'
    -v /home/jenkins:/var/jenkins_home \
    -d qubestash/jenkins:latest 
```