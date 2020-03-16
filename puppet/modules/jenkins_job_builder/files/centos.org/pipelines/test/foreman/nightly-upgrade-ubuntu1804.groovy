def playBookVars() {
    playBook = pipelineVars(action: 'upgrade', type: 'foreman', version: 'nightly', os: 'ubuntu1804')
    return playBook
}
