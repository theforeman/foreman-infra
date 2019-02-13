def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-devel-centos7'], 'pipeline': 'katello_pipeline.yml', 'extraVars': ['katello_version': 'devel']]
    return playBook
}
