def runPlaybook(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {

        def extraVars = [:]
        def defaultVars = [:]
        def inventory = config.inventory
        def tags = config.tags
        def limit = config.limit

        if (config.extraVars) {
            extraVars = defaultVars + config.extraVars
        } else {
            extraVars = defaultVars
        }

        ansiblePlaybook(
            playbook: config.playbook,
            inventory: inventory,
            colorized: true,
            limit: limit,
            tags: tags,
            extraVars: extraVars
        )

    }
}
