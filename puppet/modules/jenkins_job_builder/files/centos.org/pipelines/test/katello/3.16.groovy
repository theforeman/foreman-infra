def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'katello', version: '3.16', os: 'centos7')
    return playBook
}

