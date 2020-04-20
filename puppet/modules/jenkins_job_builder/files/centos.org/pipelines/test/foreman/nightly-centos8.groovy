def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'foreman', version: 'nightly', os: 'centos8')
    return playBook
}
