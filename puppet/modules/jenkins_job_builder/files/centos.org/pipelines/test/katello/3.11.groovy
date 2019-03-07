def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-3.11-centos7'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': '3.11', 'pipeline_os': 'centos7', 'pipeline_type': 'katello']]
    return playBook
}
