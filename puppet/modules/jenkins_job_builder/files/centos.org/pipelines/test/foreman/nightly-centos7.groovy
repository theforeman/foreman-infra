def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'foreman', version: 'nightly', os: 'centos7')
    return playBook
}
