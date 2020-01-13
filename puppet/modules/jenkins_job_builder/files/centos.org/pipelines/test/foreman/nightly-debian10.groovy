def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'foreman', version: 'nightly', os: 'debian10')
    return playBook
}
