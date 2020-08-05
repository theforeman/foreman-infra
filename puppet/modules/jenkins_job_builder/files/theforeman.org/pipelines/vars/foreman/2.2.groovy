def foreman_version = 'nightly'
def foreman_client_distros = [
    'el8',
    'el7',
    'el6',
    'el5',
    'sles12',
    'sles11'
]
def foreman_el_releases = [
    'el7',
    'el8'
]
def foreman_debian_releases = ['buster', 'bionic']
def pipelines = [
    'install': [
        'centos7',
        'centos8',
        'debian10',
        'ubuntu1804'
    ],
    'upgrade': [
        'centos7',
        'centos8',
        'debian10',
        'ubuntu1804'
    ]
]
