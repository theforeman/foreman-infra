def playBookVars() {
    playBook = ['boxes': ['pipeline-upgrade-centos7'], 'pipeline': 'katello_upgrade_pipeline.yml', 'extraVars': ['katello_version': 'nightly', 'katello_version_start': '3.10']]
    return playBook
}
