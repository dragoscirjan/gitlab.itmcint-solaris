# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Project Template
# based on Vagrant utility
#
# @link      http://github.com/dragoscirjan/project-template for the canonical source repository
# @copyright Copyright (c) 2015-present Dragos Cirjan (http://dragoscirjan.github.io)
# @license   https://github.com/dragoscirjan/project-template/blob/master/LICENSE MIT
#

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

  ####################################################################################################################
  # Vagrant init config
  ####################################################################################################################

  $ubuntu_ip = {
    'lxc' => '10.0.3.10',
    'virtualbox' => ''
  }

  ####################################################################################################################
  # Provider custom config
  ####################################################################################################################

  # Uncomment this if you're using LXC provider // --provider lxc
  ####################################################################################################################

  # config.vm.provider :lxc do |lxc|
  #   lxc.backingstore = 'none' # @see https://github.com/fgrehm/vagrant-lxc#backingstore-options
  #
  #   # uncomment for Eclipse CHE
  #   # lxc.customize 'aa_profile', 'lxc-container-default-with-nesting'
  #   lxc.customize 'aa_profile', 'unconfined'
  #
  #   # add your global lxc config here
  # end

  # Uncomment this if you're using Virtualbox provider // --provider virtualbox
  ####################################################################################################################

  # # --provider virtualbox
  # config.vm.provider :virtualbox do |virtualbox|
  #   # add your global lxc config here
  # end

  # Uncomment this if you're using Libvirt provider // --provider libvirt
  ####################################################################################################################

  # # --provider libvirt
  # config.vm.provider :libvirt do |libvirt|
  #   # add your global lxc config here
  #   libvirt.driver = "qemu"
  # end

  ####################################################################################################################
  # Boxes config (based on provider)
  # Please do not change this config zone. If you require provider based configuration, please use the previous
  # section.
  ####################################################################################################################

  # Uncomment this if you're using a Centos Machine
  ####################################################################################################################

  # config.vm.define :centos do |centos|
  #   # --provider lxc
  #   centos.vm.provider :lxc do |lxc, override|
  #     lxc.customize "network.ipv4", "10.0.3.20/24"
  #
  #     # override.vm.box = "dragosc/centos6"
  #     override.vm.box = "dragosc/centos7"
  #   end
  #
  #   # --provider virtualbox
  #   centos.vm.provider :virtualbox do |virtualbox, override|
  #     override.vm.network "private_network", ip: "192.168.50.20"
  #
  #     override.vm.box = "centos/7"
  #   end
  #
  #   # # --provider libvirt
  #   # centos.vm.provider :libvirt do |libvirt, override|
  #   #   # TODO: What network ip is using libvirt by default ?
  #   #   # override.vm.network "private_network", ip: "192.168.50.20"
  #   #
  #   #   override.vm.box = "centos/7"
  #   #   override.vm.box = "dragosc/centos-7" # TODO: This VM hasn't been verified yet
  #   # end
  # end

  # Uncomment this if you're using a Debian Machine
  ####################################################################################################################

  # config.vm.define :debian do |debian|
  #   # # --provider lxc
  #   # debian.vm.provider :lxc do |lxc, override|
  #   #   lxc.customize "network.ipv4", "10.0.3.10/24"
  #   #
  #   #   # TODO: Build box
  #   #   override.vm.box = "dragosc/debian8"
  #   # end
  #
  #   # --provider virtualbox
  #   debian.vm.provider :virtualbox do |virtualbox, override|
  #     override.vm.network "private_network", ip: "192.168.50.10"
  #
  #
  #     # override.vm.box = "debian/wheezy64" # 7
  #     override.vm.box = "debian/jessie64" # 8
  #   end
  #
  #   # # --provider libvirt
  #   # debian.vm.provider :libvirt do |libvirt, override|
  #   #   raise Vagrant::Errors::VagrantError.new, "We didn't configure our Vagrantfile for the 'libvirt' provider"
  #   # end
  # end

  # Uncomment this if you're using a Oracle Machine
  ####################################################################################################################

  # config.vm.define :oracle do |oracle|
  #   # --provider lxc
  #   oracle.vm.provider :lxc do |lxc, override|
  #     lxc.customize "network.ipv4", "10.0.3.30/24"
  #
  #     override.vm.box = "dragosc/oracle65"
  #   end
  #
  #   # --provider virtualbox
  #   oracle.vm.provider :virtualbox do |virtualbox, override|
  #     override.vm.network "private_network", ip: "192.168.50.30"
  #
  #     # override.vm.box = 'boxcutter/ol65'
  #     # override.vm.box = 'boxcutter/ol67'
  #     override.vm.box = 'boxcutter/ol71'
  #   end
  #
  #   # # --provider libvirt
  #   # oracle.vm.provider :libvirt do |libvirt, override|
  #   #   raise Vagrant::Errors::VagrantError.new, "We didn't configure our Vagrantfile for the 'libvirt' provider"
  #   # end
  # end

  # Uncomment this if you're using a Ubuntu Machine
  ####################################################################################################################

  config.vm.define :ubuntu do |ubuntu|
    # --provider lxc
    ubuntu.vm.provider :lxc do |lxc, override|
      lxc.customize "network.ipv4", "10.0.3.101/24"

      override.vm.box = "dragosc/trusty64"
    end

    # --provider virtualbox
    ubuntu.vm.provider :virtualbox do |virtualbox, override|
      override.vm.network "private_network", ip: "192.168.50.101"

      virtualbox.memory = 2048
      # virtualbox.cpus = 1

      # override.vm.box = "ubuntu/xenial64" # 16.04 - NOT LAUNCHED
      # override.vm.box = "ubuntu/wily64" # 15.10
      # override.vm.box = "ubuntu/vivid64" # 15.04
      override.vm.box = "ubuntu/trusty64" # 14.04
      # override.vm.box = "ubuntu/xenial64" # 16.04
    end

    # # --provider libvirt
    # ubuntu.vm.provider :libvirt do |libvirt, override|
    #   raise Vagrant::Errors::VagrantError.new, "We didn't configure our Vagrantfile for the 'libvirt' provider"
    # end
  end

  ####################################################################################################################
  # Provisioning
  ####################################################################################################################

  # Uncomment this if you're using Shell (inline) provisioning
  # @link https://docs.vagrantup.com/v2/provisioning/shell.html
  ####################################################################################################################

  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL

  # Uncomment this if you're using Shell (file) provisioning
  # @link https://docs.vagrantup.com/v2/provisioning/file.html
  ####################################################################################################################
  config  .vm.provision "shell", path: ".provision/ubuntu.sh"
  # config.vm.provision "shell", path: ".provision-boot.sh", run: "always"

  # Uncomment this if you're using Ansible provisioning
  # @link https://docs.vagrantup.com/v2/provisioning/ansible.html
  # @link https://docs.vagrantup.com/v2/provisioning/ansible_local.html
  ####################################################################################################################

  # config.vm.provision :ansible do |ansible|
  #   ansible.groups = {
  #     "all_groups:children" => [
  #       # 'debian',
  #       'ubuntu',
  #       # 'centos',
  #       # 'oracle'
  #     ]
  #   }
  #   ansible.playbook = ".provision.yml"
  # end

  ####################################################################################################################
  # Eclipse CHE
  ####################################################################################################################

  # # config.vm.network "forwarded_port", host: 8080, guest: 8080
  # # for i in 32700..32800
  # #   config.vm.network :forwarded_port, guest: i, host: i
  # # end
  # config.vm.provision "shell", path: ".provision-che.sh"
  # config.vm.provision "shell", path: ".provision-che-boot.sh", run: "always"

end
