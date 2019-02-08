def playBookVars() {
    playBook = ['boxes': ['pipeline-katello-devel'], 'pipeline': 'katello_pipeline.yml', 'extraVars': ['katello_version': 'devel']]
    return playBook
}
