void push_rpms(repo_type, version, distro) {
    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-${repo_type}-${version}/${distro} -S repo_dest=${repo_type}/${version}/${distro}"])
}

void mash(filename) {
    sh "ssh -o 'BatchMode yes' root@koji.katello.org ${filename}"
}
