def runPlaybook(args) {
    playbook = args.playbook
    inventory = args.inventory ?: 'localhost'
    extraVars = args.extraVars ?: [:]
    options = args.options ?: []

    def command = [
        "ansible-playbook",
        "-i ${inventory}",
        playbook
    ]

    if (options) {
        command += options
    }

    if (extraVars) {
        extra_vars_file = writeExtraVars(extraVars: extraVars)
        command.push("-e@${extra_vars_file}")
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "${command.join(' ')}"
    }
}

def writeExtraVars(args) {
    def timestamp = new Date().getTime()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '.yaml'
    def extra_vars = args.extraVars ?: [:]

    writeYaml file: extra_vars_file, data: extra_vars
    archiveArtifacts artifacts: extra_vars_file

    return extra_vars_file
}
