def obal(args) {
    def timestamp = new Date().getTime()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '.yaml'

    tags = args.tags ? "--tags ${args.tags}" : ""
    extra_vars = args.extraVars ?: [:]
    packages = args.packages
    if (packages instanceof String[]) {
        packages = packages.join(' ')
    }

    writeYaml file: extra_vars_file, data: extra_vars

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        withEnv(['ANSIBLE_FORCE_COLOR=true', "PYTHONPATH=${pwd()}/obal"]) {
            sh "python -m obal ${args.action} ${packages} ${tags} -e @${extra_vars_file}"
        }
    }

    sh "rm ${extra_vars_file}"
}

def setup_obal() {
    dir('obal') {
        checkout([
            $class : 'GitSCM',
            branches : [[name: 'master']],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [
                [url: 'https://github.com/theforeman/obal']
            ]
        ])
    }
}
