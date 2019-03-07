def playBookVars() {
    playBook = ['boxes': ['pipeline-foreman-nightly-centos7'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'centos7', 'pipeline_type': 'foreman']]
    return playBook
}
