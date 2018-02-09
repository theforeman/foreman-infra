def obal(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def tags = config.tags ? "--tags ${config.tags}" : ""
    def extra_vars = config.extraVars ?: [:]
    def extra_vars_file = 'extra_vars.yaml'

    writeYaml file: extra_vars_file, data: extra_vars
    archive extra_vars_file

    dir('obal') {
        git url: "https://github.com/theforeman/obal.git", branch: "master"
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ANSIBLE_FORCE_COLOR=true PYTHONPATH=obal python -m obal ${tags} -e @${extra_vars_file} ${config.action} ${config.packages}"
    }
}
