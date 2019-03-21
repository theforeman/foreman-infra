def playBookVars() {
    playBook = ['boxes': ['pipeline-foreman-nightly-ubuntu1604'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'ubuntu1604', 'pipeline_type': 'foreman']]
    return playBook
}
