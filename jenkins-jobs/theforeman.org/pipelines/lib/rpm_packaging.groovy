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
    git_repo = repo == 'pulpcore' ? 'pulpcore-packaging' : 'foreman-packaging'
    ws(dist) {
        dir('packaging') {
            git url: "https://github.com/theforeman/${git_repo}", branch: "rpm/${version}", poll: false
            setup_obal()
            obal(
                action: 'repoclosure',
                packages: "${repo}-repoclosure-${dist}"
            )
        }
    }
}

def repoclosures(repo, releases, version) {
    def closures = [:]

    releases.each { release ->
        closures[release] = { repoclosure(repo, release, version) }
    }

    return closures
}
