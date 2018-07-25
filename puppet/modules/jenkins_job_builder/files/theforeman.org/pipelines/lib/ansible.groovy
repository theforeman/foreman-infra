def runPlaybook(args) {
    playbook = args.playbook
    inventory = args.inventory ?: 'localhost'
    extraVars = args.extraVars ?: []
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
        extraVars = "-e " + extraVars.join(" -e ")
        command.push(extraVars)
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "${command.join(' ')}"
    }
}
