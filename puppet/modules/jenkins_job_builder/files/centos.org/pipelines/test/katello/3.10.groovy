def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-3.10-centos7'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': '3.10', 'pipeline_os': 'centos7', 'pipeline_type': 'katello']]
    return playBook
}
