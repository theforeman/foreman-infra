dnf install -y epel-release
dnf install -y ansible "dnf-command(reposync)"

pushd /root/koji-sync/podman/repos
dnf reposync --repoid AppStream --repoid PowerTools --repoid BaseOS --download-metadata

pushd /root/koji-sync/podman/koji-ansible/
ansible-playbook -i inventory/inventory master.yaml --connection=local

/usr/local/bin/rhel8-split.sh
