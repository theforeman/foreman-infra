def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'foreman', version: 'nightly', os: 'ubuntu1804')
    return playBook
}
