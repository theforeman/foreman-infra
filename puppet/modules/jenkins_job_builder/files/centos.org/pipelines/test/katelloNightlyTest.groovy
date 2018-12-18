def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-nightly-centos7'], 'pipeline': 'katello_pipeline.yml', 'extraVars': ['katello_version': 'nightly']]
    return playBook
}
