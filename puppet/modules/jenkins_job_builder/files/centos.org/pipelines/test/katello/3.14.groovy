def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-server-3.14-centos7'], 'pipeline': 'install_pipeline.yml', 'extraVars': ['pipeline_version': '3.14', 'pipeline_os': 'centos7', 'pipeline_type': 'katello']]
    return playBook
}
