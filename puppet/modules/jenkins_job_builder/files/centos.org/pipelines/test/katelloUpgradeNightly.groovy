def playBookVars() {
    playBook = ['boxes': ['pipeline-upgrade-centos7'], 'pipeline': 'pipeline_katello_upgrade.yml', 'extraVars': ['katello_version': 'nightly']]
    return playBook
}
