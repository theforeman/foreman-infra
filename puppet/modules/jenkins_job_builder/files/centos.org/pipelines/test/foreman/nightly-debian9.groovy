def playBookVars() {
    playBook = ['boxes': ['pipeline-foreman-server-nightly-debian9'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'debian9', 'pipeline_type': 'foreman']]
    return playBook
}
