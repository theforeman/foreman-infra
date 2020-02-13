def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: '3.15', os: 'centos7')
    return playBook
}
