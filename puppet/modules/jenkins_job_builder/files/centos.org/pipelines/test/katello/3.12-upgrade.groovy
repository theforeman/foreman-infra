def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: '3.12', os: 'centos7')
    return playBook
}
