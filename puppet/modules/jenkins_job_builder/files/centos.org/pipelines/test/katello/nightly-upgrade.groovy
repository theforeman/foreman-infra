def playBookVars() {
    playBook = ['boxes': ['pipeline-upgrade-katello-nightly-centos7'], 'pipeline': 'upgrade_pipeline.yml', 'extraVars': ['pipeline_version': 'nightly', 'pipeline_os': 'centos7', 'pipeline_type': 'katello']]
    return playBook
}
