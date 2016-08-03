# A Project Template

A template for any project to start

Using 
* Vagrant; 
* Docker (TODO), Libvirt (KVM), LXC & VirtualBox
* Bash & Ansible Provisioning

## Vagrant Setup

### Installing Virtuabox

```bash
# For DEB bases:
apt-get install -y virtualbox virtualbox-dkms virtualbox-guest-dkms \
  virtualbox-guest-utils virtualbox-qt wget
# For RPM based:
# TODO: Write how to
```

### Installing LXC

```bash
# For DEB Based:
apt-get install -y bridge-utils lxc lxc-dbg lxc-templates lxc-tests git
# For RPM based:
# TODO: Write how to
# Create LXC boxes
# Read documentation on https://github.com/dragoscirjan/vagrant-lxc-base-boxes
git clone https://github.com/dragoscirjan/vagrant-lxc-base-boxes /opt/vagrant-lxc-base-boxes
cd /opt/vagrant-lxc-base-boxes && make trusty
cd /opt/vagrant-lxc-base-boxes && make centos
```

### Installing VMWare

```bash
# TODO: Write how to
```

### Installing Vagrant

```bash
# For DEB Based:
VAGRANTURL=`wget http://www.vagrantup.com/downloads.html -qO - | grep deb | grep x86_64 | awk -F '"' '{ print $2 }'`
wget "$VAGRANTURL" -O "/tmp/vagrant.deb" && dpkg -i /tmp/vagrant.deb
# For RPM based:
VAGRANTURL=`wget http://www.vagrantup.com/downloads.html -qO - | grep rpm | grep x86_64 | awk -F '"' '{ print $2 }'`
wget "$VAGRANTURL" -O "/tmp/vagrant.rpm" && rpm -i /tmp/vagrant.rpm
```

#### Installing Vagrant LXC Plugin

```bash
vagrant plugin install vagrant-lxc
```

#### Installing Vagrant VMware Plugin

```bash
# For VMware Fusion
vagrant plugin install vagrant-vmware-fusion
# For WMware Worksation
vagrant plugin install vagrant-vmware-workstation
```

## Vagrantfile

Vagrant config file. Please add any other config options that you may need.

## Boostrap Script

Done by *Vagrant_setup.sh*. Please add any setup script you need for your server.

## Startup Script

Done by *Vagrant_boot.sh*. Please add any startup script you need for your server.
