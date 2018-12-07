def runPlaybook(args) {
    playbook = args.playbook
    inventory = args.inventory ?: 'localhost'
    extraVars = args.extraVars ?: [:]
    sensitiveExtraVars = args.sensitiveExtraVars ?: [:]
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
        command.push("-e @${extra_vars_file}")
    }

    if (sensitiveExtraVars) {
        sensitive_extra_vars_file = writeExtraVars(extraVars: sensitiveExtraVars, archiveExtraVars: false)
        command.push("-e @${sensitive_extra_vars_file}")
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "${command.join(' ')}"
    }
}

def writeExtraVars(args) {
    def timestamp = System.currentTimeMillis()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '.yaml'
    def extra_vars = args.extraVars ?: [:]
    def archive_extra_vars = (args.archiveExtraVars != null) ? args.archiveExtraVars : true

    writeYaml file: extra_vars_file, data: extra_vars
    if (archive_extra_vars) {
        archiveArtifacts artifacts: extra_vars_file
    }

    return extra_vars_file
}
