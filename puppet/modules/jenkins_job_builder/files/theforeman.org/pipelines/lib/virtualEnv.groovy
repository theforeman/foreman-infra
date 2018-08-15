def virtEnv(path, command) {
    dir(path) {
        if(!fileExists('venv')) {
            sh "virtualenv venv"
        }

        sh """
        source venv/bin/activate
        ${command}
        deactivate
        """
    }
}
