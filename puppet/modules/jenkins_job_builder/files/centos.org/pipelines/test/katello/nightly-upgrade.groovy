def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'katello', version: 'nightly', os: 'centos7')
    return playBook
}
