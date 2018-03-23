def obal(args) {
    def extra_vars_file = 'extra_vars.yaml'

    tags = args.tags ? "--tags ${args.tags}" : ""
    extra_vars = args.extraVars ?: [:]
    packages = args.packages
    if (packages instanceof String[]) {
        packages = packages.join(' ')
    }

    writeYaml file: extra_vars_file, data: extra_vars

    dir('obal') {
        git url: "https://github.com/theforeman/obal.git", branch: "master"
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        withEnv(['ANSIBLE_FORCE_COLOR=true', "PYTHONPATH=${pwd()}/obal"]) {
            sh "python -m obal ${tags} -e @${extra_vars_file} ${args.action} ${packages}"
        }
    }

    sh "rm ${extra_vars_file}"
}
