def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'luna', version: 'nightly', os: 'centos7')
    return playBook
}
