def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'katello', version: '3.14', os: 'centos7')
    return playBook
}
