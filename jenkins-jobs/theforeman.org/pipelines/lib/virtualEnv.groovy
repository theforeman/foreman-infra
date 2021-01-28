def virtEnv(path, command) {
    if(!fileExists("${path}/bin/activate")) {
        sh "virtualenv ${path}"
    }

    sh """
    source ${path}/bin/activate
    ${command}
    deactivate
    """
}
