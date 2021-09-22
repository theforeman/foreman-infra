# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "install puppet", type: "shell", inline: <<-SHELL
    . /etc/os-release
    yum -y install epel-release
    yum -y install puppet6-release || yum -y install https://yum.puppetlabs.com/puppet6/puppet6-release-el-${VERSION_ID}.noarch.rpm
    yum -y install puppet-agent
  SHELL

  config.vm.provision "run puppet", type: 'puppet' do |puppet|
    puppet.module_path = ["puppet/modules", "puppet/git_modules", "puppet/forge_modules"]
    puppet.manifests_path = "vagrant/manifests"
    puppet.synced_folder_type = "rsync"
  end

  config.vm.define "jenkins-master" do |override|
    override.vm.hostname = "jenkins-master"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "2048"
    end
  end

  config.vm.define "jenkins-node-el7" do |override|
    override.vm.hostname = "jenkins-node-el7"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "4096"
    end

    # Note that VAGRANT_EXPERIMENTAL=dependency_provisioners must be used for
    # before: all to work.
    override.vm.provision "PUP-10548 SELinux workaround", type: "shell", before: :all, inline: <<-SHELL
      yum -y install centos-release-scl-rh
      yum -y install rh-postgresql12-postgresql-server
    SHELL
  end

  config.vm.define "jenkins-node-el8" do |override|
    override.vm.hostname = "jenkins-node-el8"
    override.vm.box = "centos/8"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "4096"
    end
  end

  config.vm.define "jenkins-node-debian10" do |override|
    override.vm.hostname = "jenkins-node-debian10"
    override.vm.box = "debian/buster64"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "4096"
    end
    config.vm.provision "install puppet", type: "shell", inline: <<-SHELL
      . /etc/os-release
      wget https://apt.puppet.com/puppet6-release-${VERSION_CODENAME}.deb
      apt-get install -y ./puppet6-release-${VERSION_CODENAME}.deb
      apt-get update
      apt-get install -y puppet-agent
    SHELL
  end

  config.vm.define "jenkins-deb-node-debian11" do |override|
    override.vm.hostname = "jenkins-deb-node-debian11"
    override.vm.box = "debian/bullseye64"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "4096"
    end
    config.vm.provision "install puppet", type: "shell", inline: <<-SHELL
      . /etc/os-release
      wget https://apt.puppet.com/puppet6-release-${VERSION_CODENAME}.deb
      apt-get install -y ./puppet6-release-${VERSION_CODENAME}.deb
      apt-get update
      apt-get install -y puppet-agent
    SHELL
  end

  config.vm.define "web" do |override|
    override.vm.hostname = "web"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "2048"
    end
  end
end
