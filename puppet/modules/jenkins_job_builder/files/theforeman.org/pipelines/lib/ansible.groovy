def runPlaybook(args) {
    playbook = args.playbook
    inventory = args.inventory ?: 'localhost'
    extraVars = args.extraVars ?: [:]
    sensitiveExtraVars = args.sensitiveExtraVars ?: [:]
    options = args.options ?: []
    commandLineExtraVars = args.commandLineExtraVars ?: false
    venv = args.venv

    def command = [
        "ansible-playbook",
        "-i ${inventory}",
        playbook
    ]

    if (options) {
        command += options
    }

    if (extraVars) {
        if (commandLineExtraVars) {
          extra_vars = buildExtraVars(extraVars: extraVars)
          command.push(extra_vars)
        } else {
          extra_vars_file = writeExtraVars(extraVars: extraVars)
          command.push("-e @${extra_vars_file}")
        }
    }

    if (sensitiveExtraVars) {
        sensitive_extra_vars_file = writeExtraVars(extraVars: sensitiveExtraVars, archiveExtraVars: false)
        command.push("-e @${sensitive_extra_vars_file}")
    }

    def command_string = command.join(' ')

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        if (venv) {
            virtEnv(venv, command_string)
        } else {
            sh command_string
        }
    }
}

def writeExtraVars(args) {
    def timestamp = System.currentTimeMillis()
    def uuid = UUID.randomUUID()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '-' + uuid.toString() + '.yaml'
    def extra_vars = args.extraVars ?: [:]
    def archive_extra_vars = (args.archiveExtraVars != null) ? args.archiveExtraVars : true

    writeYaml file: extra_vars_file, data: extra_vars
    if (archive_extra_vars) {
        archiveArtifacts artifacts: extra_vars_file
    }

    return extra_vars_file
}

def buildExtraVars(args) {
    def timestamp = System.currentTimeMillis()
    def uuid = UUID.randomUUID()
    def extra_vars_file = 'extra_vars-' + timestamp.toString() + '-' + uuid.toString()
    def extra_vars = args.extraVars ?: [:]
    def extra_vars_string = ''
    def archive_extra_vars = (args.archiveExtraVars != null) ? args.archiveExtraVars : true

    for(extraVar in extra_vars) {
      extra_vars_string += " -e ${extraVar.key}=${extraVar.value}"
    }

    writeFile file: extra_vars_file, text: extra_vars_string

    if (archive_extra_vars) {
        archiveArtifacts artifacts: extra_vars_file
    }

    return extra_vars_string
}
