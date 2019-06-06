def update_build_description_from_packages(packages_to_build) {
    build_description = packages_to_build
    if (build_description instanceof String[]) {
        build_description = build_description.join(' ')
    }
    currentBuild.description = build_description
}

def diff_filter(range, filter, path) {
    return sh(returnStdout: true, script: "git diff ${range} --name-only --diff-filter=${filter} -- '${path}'").trim()
}

def find_added_or_changed_files(diff_range, path) {
    return diff_filter(diff_range, 'ACMRTUXB', path)
}

def find_deleted_files(diff_range, path) {
    return diff_filter(diff_range, 'D', path)
}

def find_changed_files(diff_range, path) {
    return diff_filter(diff_range, 'M', path)
}

def find_changed_packages(diff_range) {
    def changed_packages = find_added_or_changed_files(diff_range, 'packages/**.spec')

    if (changed_packages) {
        changed_packages = sh(returnStdout: true, script: "echo '${changed_packages}' | xargs dirname | xargs -n1 basename |sort -u").trim()
    } else {
        changed_packages = ''
    }

    return changed_packages.split()
}

def query_rpmspec(specfile, queryformat) {
    result = sh(returnStdout: true, script: "rpmspec -q --srpm --undefine=dist --undefine=foremandist --queryformat=${queryformat} ${specfile}").trim()
    return result
}

def repoclosure(repo, dist, version) {
    version = version == 'nightly' ? 'develop' : version
    ws(dist) {
        dir('packaging') {
            git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/${version}", poll: false
            setup_obal()
            obal(
                action: 'repoclosure',
                packages: "${repo}-repoclosure-${dist}"
            )
        }
    }
}

def repoclosures(repo, versions) {
    def results = [:]

    // Run all repoclosure steps sequentially and store the result because
    // yum on EL7 aggressively shares caches which breaks concurrent
    // repoclosures
    versions.each { version, distros ->
        distros.each { distro, os ->
            script {
                stage("repoclosure-${version}-${distro}") {
                    script {
                        try {
                            repoclosure('plugins', distro, version)
                            results["${version}-${distro}"] = true
                        } catch(Exception ex) {
                            results["${version}-${distro}"] = ex
                        }
                    }
                }
            }
        }
    }

    return results
}
