def playBookVars() {
    playBook = pipelineVars(action: 'install', type: 'foreman', version: params.foreman_version, os: params.distro, extra_vars: ['foreman_expected_version': params.expected_version])
    return playBook
}
