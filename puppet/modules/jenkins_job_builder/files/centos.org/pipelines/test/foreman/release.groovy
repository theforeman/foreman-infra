def playBookVars() {
    playBook = [
        'boxes': ["pipeline-foreman-${params.foreman_version}-${params.distro}"],
        'pipeline': 'install_pipeline.yml',
        'extraVars': [
            'pipeline_version': params.foreman_version,
            'pipeline_os': params.distro,
            'pipeline_type': 'foreman',
            'foreman_expected_version': params.expected_version
        ]
    ]
    return playBook
}
