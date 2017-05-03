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
      lxc.container_name = 'solaris'
      # lxc.customize "network.ipv4", "10.0.3.101/24"
      lxc.customize 'aa_profile', 'unconfined'
      lxc.customize 'cap.drop', nil
      override.vm.box = "dragosc/xenial64"
    end

    # --provider virtualbox
    ubuntu.vm.provider :virtualbox do |virtualbox, override|
      override.vm.network "private_network", ip: "192.168.50.101"
      override.vm.box = "ubuntu/xenial64" # 16.04
    end
  end

  config.vm.provision :shell, inline: "bash /vagrant/run.sh"

end
