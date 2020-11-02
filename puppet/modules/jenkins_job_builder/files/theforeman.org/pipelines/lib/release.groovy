void push_foreman_rpms(repo_type, version, distros) {
    version = version == 'develop' ? 'nightly' : version
    keep_old_files = version != 'nightly'
    for (distro in distros) {
        if repo_type {
            push_rpms("foreman-${repo_type}-${version}", repo_type, version, distro, keep_old_files)
        } else {
            push_rpms_direct("foreman-${version}/${distro}", "releases/${version}/${distro}", false, true)
        }
    }
}

void push_rpms(repo_src, repo_dest, version, distro, keep_old_files = false) {
    push_rpms_direct("${repo_src}/${distro}", "${repo_dest}/${version}/${distro}", !keep_old_files, keep_old_files)
}

void push_rpms_direct(repo_source, repo_dest, overwrite = true, merge = false) {
    sshagent(['repo-sync']) {
        sh "ssh yumrepo@web01.osuosl.theforeman.org ${repo_source} ${repo_dest} ${overwrite} ${merge}"
    }
}

void push_rpms_katello(version) {
    sshagent(['katello-fedorapeople']) {
        sh "ssh katelloproject@fedorapeople.org 'cd /project/katello/bin && sh rsync-repos-from-koji ${version}'"
    }
}

void push_debs_direct(os, repo) {
    sshagent(['freight']) {
        sh "ssh freight@web01.osuosl.theforeman.org deploy ${os} ${repo}"
    }
}

void push_pulpcore_rpms(version, distro) {
    push_rpms("pulpcore-${version}", "pulpcore", version, distro, true)
}

void mash(collection, version) {
    sshagent(['mash']) {
        sh "ssh -o 'BatchMode yes' root@koji.katello.org collection-mash-split.py ${collection} ${version}"
    }
}
