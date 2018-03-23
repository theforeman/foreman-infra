def update_build_description_from_packages(packages_to_build) {
    build_description = packages_to_build
    if (build_description instanceof String[]) {
        build_description = build_description.join(' ')
    }
    currentBuild.description = build_description
}

def find_changed_packages(diff_range) {
    def changed_packages = sh(returnStdout: true, script: "git diff ${diff_range} --name-only --diff-filter=ACMRTUXB -- 'packages/**.spec'").trim()

    if (changed_packages) {
        changed_packages = sh(returnStdout: true, script: "echo '${changed_packages}' | xargs dirname | xargs -n1 basename |sort -u").trim()
    } else {
        changed_packages = ''
    }

    return changed_packages.split()
}
