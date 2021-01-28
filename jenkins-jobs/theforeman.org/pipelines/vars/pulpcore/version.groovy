def pulpcore_version = '{version}'
def pulpcore_distros = ['el7', 'el8']
def packaging_branch = 'rpm/{version}'
def pipelines = [
    'pulpcore': [
        'centos7',
        'centos8'
    ]
]
