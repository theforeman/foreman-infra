def playBookVars() {
    playBook = ['boxes': ['pipeline-foreman-server-nightly-ubuntu1804'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'ubuntu1804', 'pipeline_type': 'foreman']]
    return playBook
}
