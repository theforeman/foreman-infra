def obal(args) {
    def timestamp = new Date().getTime()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '.yaml'

    def tags = args.tags ? "--tags ${args.tags}" : ""
    def extra_vars = args.extraVars ?: [:]
    def packages = args.packages
    if (packages instanceof String[]) {
        packages = packages.join(' ')
    }

    writeYaml file: extra_vars_file, data: extra_vars
    archiveArtifacts artifacts: extra_vars_file

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        withEnv(['ANSIBLE_FORCE_COLOR=true', "PYTHONPATH=${env.WORKSPACE}/obal"]) {
            sh "python -m obal ${args.action} ${packages} ${tags} -e @${extra_vars_file}"
        }
    }

    sh "rm ${extra_vars_file}"
}

def setup_obal() {
    dir("${env.WORKSPACE}/obal") {
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
