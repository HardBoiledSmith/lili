# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "hbsmith/awslinux"

  config.vm.provider "virtualbox" do |v|
    v.name = 'hbsmith-lili'
    v.cpus = 1
    v.memory = 256
  end

  config.vm.provision "shell", inline: "yum -y install python35"
  config.vm.provision "shell", path: "provisioning.py"
  config.vm.network "private_network", ip: "192.168.100.100"
end
