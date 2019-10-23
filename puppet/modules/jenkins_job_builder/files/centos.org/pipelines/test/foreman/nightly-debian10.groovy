def playBookVars() {
    playBook = ['boxes': ['pipeline-foreman-server-nightly-debian10'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'debian10', 'pipeline_type': 'foreman']]
    return playBook
}
