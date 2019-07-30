void push_foreman_rpms(repo_type, version, distro) {
    version = version == 'develop' ? 'nightly' : version
    push_rpms("foreman-${repo_type}-${version}", repo_type, version, distro)
}

void push_rpms(repo_src, repo_dest, version, distro) {
    push_rpms_direct("${repo_src}/${distro}", "${repo_dest}/${version}/${distro}")
}

void push_rpms_direct(repo_source, repo_dest, overwrite = true, merge = false) {
    sshagent(['repo-sync']) {
        withRVM(["cap yum repo:sync -S overwrite=${overwrite} -S merge=${merge} -S repo_source=${repo_source} -S repo_dest=${repo_dest}"])
    }
}

void push_rpms_katello(version) {
    sshagent(['katello-fedorapeople']) {
        sh "ssh katelloproject@fedorapeople.org 'cd /project/katello/bin && sh rsync-repos-from-koji ${version}'"
    }
}

void push_debs_direct(os, repo) {
    sshagent(['freight']) {
        sh "ssh freight@deb.theforeman.org deploy ${os} ${repo}"
    }
}

void mash(filename, version = '') {
    sshagent(['mash']) {
        sh "ssh -o 'BatchMode yes' root@koji.katello.org ${filename} ${version}"
    }
}
