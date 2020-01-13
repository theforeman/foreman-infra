def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: '3.14', os: 'centos7')
    return playBook
}
