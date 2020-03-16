def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: 'nightly', os: 'debian10')
    return playBook
}
