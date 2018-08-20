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

def containerPlaybook(playbook) {
    dir('containers') {
        runPlaybook(
            playbook: playbook,
            inventory: cico_inventory('../'),
            extraVars: ['@vars/remote.yml'],
            options: ['-b']
        )
    }
}

def ansibleModulesPlaybook(playbook, route) {
    dir('ansible-modules') {
        runPlaybook(
            playbook: playbook,
            inventory: cico_inventory('../'),
            extraVars: ['@../containers/vars/remote.yml', "foreman_server_url=https://${route}"],
        )
    }
}
