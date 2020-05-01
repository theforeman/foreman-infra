def foreman_version = '1.24'
def foreman_client_distros = [
    'el7',
    'el6',
    'el5',
    'fc29',
    'sles12',
    'sles11'
]
def foreman_el_releases = [
    'el7'
]
def foreman_debian_releases = ['stretch', 'buster', 'xenial', 'bionic']
def pipelines = [
    'install': [
        'centos7',
        'debian9',
        'debian10',
        'ubuntu1604',
        'ubuntu1804'
    ]
]
