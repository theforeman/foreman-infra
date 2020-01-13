def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: '3.13', os: 'centos7')
    return playBook
}
