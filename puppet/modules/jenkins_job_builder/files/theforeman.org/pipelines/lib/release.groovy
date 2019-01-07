void push_foreman_rpms(repo_type, version, distro) {
    push_rpms("foreman-${repo_type}-${version}", repo_type, version, distro)
}

void push_rpms(repo_src, repo_dest, version, distro) {
    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=${repo_src}/${distro} -S repo_dest=${repo_dest}/${version}/${distro}"])
}

void mash(filename) {
    sh "ssh -o 'BatchMode yes' root@koji.katello.org ${filename}"
}
