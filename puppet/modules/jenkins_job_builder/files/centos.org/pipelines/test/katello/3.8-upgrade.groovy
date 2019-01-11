def playBookVars() {
    playBook = ['boxes': ['pipeline-upgrade-centos7'], 'pipeline': 'katello_upgrade_pipeline.yml', 'extraVars': ['katello_version': '3.8', 'katello_version_start: '3.7']]
    return playBook
}
