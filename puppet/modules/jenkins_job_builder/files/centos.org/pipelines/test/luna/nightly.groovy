def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'luna', version: 'nightly', os: 'centos7')
    return playBook
}
