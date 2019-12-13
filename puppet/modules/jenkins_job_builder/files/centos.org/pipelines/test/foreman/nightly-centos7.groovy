def playBookVars() {
    playBook = [
      'boxes': ['pipeline-foreman-server-nightly-centos7', 'pipeline-foreman-smoker-nightly-centos7'],
      'pipeline': 'install_pipeline.yml',
      'extraVars': [
        'pipeline_version': 'nightly',
        'pipeline_os': 'centos7',
        'pipeline_type': 'foreman'
      ]
    ]
    return playBook
}
