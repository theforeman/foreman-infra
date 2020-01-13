def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'katello', version: 'nightly', os: 'centos7')
    return playBook
}
