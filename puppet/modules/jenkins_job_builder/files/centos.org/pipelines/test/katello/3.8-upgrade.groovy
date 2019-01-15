def playBookVars() {
    playBook = [
                'boxes': ['pipeline-upgrade-centos7'],
                'pipeline': 'katello_upgrade_pipeline.yml',
                'extraVars': ['katello_version': '3.8'],
                'skipTags': ['intermediate']
               ]
    return playBook
}
