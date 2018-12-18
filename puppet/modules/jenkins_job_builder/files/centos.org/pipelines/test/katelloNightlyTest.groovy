def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-nightly-centos7'], 'pipeline': 'pipeline_katello.yml', 'extraVars': ['katello_version': 'nightly']]
    return playBook
}
