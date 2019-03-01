def obal(args) {
    def extra_vars_file = writeExtraVars(extraVars: args.extraVars)
    def packages = args.packages
    if (packages instanceof String[]) {
        packages = packages.join(' ')
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        withEnv(['ANSIBLE_FORCE_COLOR=true', "PYTHONPATH=${env.WORKSPACE}/obal"]) {
            sh "python -m obal ${args.action} ${packages} -e @${extra_vars_file}"
        }
    }

    sh "rm ${extra_vars_file}"
}

def setup_obal() {
    dir("${env.WORKSPACE}/obal") {
        checkout([
            $class : 'GitSCM',
            poll: false,
            branches : [[name: 'master']],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [
                [url: 'https://github.com/theforeman/obal']
            ]
        ])
    }
}
