def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-3.10-centos7'], 'pipeline': 'katello_pipeline.yml', 'extraVars': ['katello_version': '3.10']]
    return playBook
}
