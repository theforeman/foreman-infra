def playBookVars() {
    playBook = ['boxes': ['pipeline-upgrade-luna-nightly-centos7'], 'pipeline': 'upgrade_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'centos7', 'pipeline_type': 'luna']]
    return playBook
}
