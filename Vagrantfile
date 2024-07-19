# -*- mode: ruby -*-
# vi: set ft=ruby :

CENTOS_8_BOX_URL = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-Vagrant-8-20220913.0.x86_64.vagrant-libvirt.box"
CENTOS_9_BOX_URL = "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-Vagrant-9-latest.x86_64.vagrant-libvirt.box"

Vagrant.configure("2") do |config|
  config.vm.box = "centos/stream9"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "puppet/data", "/tmp/vagrant-puppet/data", type: "rsync"

  config.vm.provision "install puppet", type: "shell", inline: <<-SHELL
    . /etc/os-release
    yum -y install epel-release
    yum -y install puppet7-release || yum -y install https://yum.puppetlabs.com/puppet7-release-el-${VERSION_ID}.noarch.rpm
    yum -y install puppet-agent
  SHELL

  config.vm.provision "run puppet", type: 'puppet' do |puppet|
    puppet.hiera_config_path = 'vagrant/hiera.yaml'
    puppet.module_path = ["puppet/modules", "puppet/external_modules"]
    puppet.manifests_path = "vagrant/manifests"
    puppet.synced_folder_type = "rsync"
    puppet.working_directory = "/tmp/vagrant-puppet"
  end

  config.vm.define "jenkins-controller" do |override|
    override.vm.hostname = "jenkins-controller"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "2048"
      provider.vm.box_url = CENTOS_9_BOX_URL
    end
  end

  config.vm.define "jenkins-node-el7" do |override|
    override.vm.hostname = "jenkins-node-el7"
    override.vm.box = "centos/7"

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
    override.vm.box = "centos/stream8"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "4096"
      provider.vm.box_url = CENTOS_8_BOX_URL
    end
  end

  config.vm.define "jenkins-node-el9" do |override|
    override.vm.hostname = "jenkins-node-el9"
    override.vm.box = "centos/stream9"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "4096"
      provider.vm.box_url = CENTOS_9_BOX_URL
    end
  end

  config.vm.define "jenkins-deb-node-debian11" do |override|
    override.vm.hostname = "jenkins-deb-node-debian11"
    override.vm.box = "debian/bullseye64"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "4096"
    end
    override.vm.provision "install puppet", type: "shell", inline: <<-SHELL
      . /etc/os-release
      wget https://apt.puppet.com/puppet7-release-${VERSION_CODENAME}.deb
      apt-get install -y ./puppet7-release-${VERSION_CODENAME}.deb
      apt-get update
      apt-get install -y puppet-agent
    SHELL
  end

  config.vm.define "web" do |override|
    override.vm.hostname = "web"
    override.vm.box = "centos/7"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "2048"
    end
  end

  config.vm.define "backup" do |override|
    override.vm.hostname = "backup"
    override.vm.box = "centos/stream8"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "2048"
      provider.vm.box_url = CENTOS_8_BOX_URL
    end
  end

  config.vm.define "redmine" do |override|
    override.vm.hostname = "redmine"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "2048"
      provider.vm.box_url = CENTOS_9_BOX_URL
    end
  end

  config.vm.define "discourse" do |override|
    override.vm.hostname = "discourse"
    override.vm.box = "centos/stream9"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "2048"
      libvirt.machine_virtual_size = 40
      provider.vm.box_url = CENTOS_9_BOX_URL
    end
  end

  config.vm.define "repo-deb" do |override|
    override.vm.hostname = "repo-deb"
    override.vm.box = "centos/stream9"

    override.vm.provider "libvirt" do |libvirt, provider|
      libvirt.memory = "2048"
      libvirt.machine_virtual_size = 40
      provider.vm.box_url = CENTOS_9_BOX_URL
    end
  end
end
