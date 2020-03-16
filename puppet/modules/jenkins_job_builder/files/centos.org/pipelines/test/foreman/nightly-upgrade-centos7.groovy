def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: 'nightly', os: 'centos7')
    return playBook
}
