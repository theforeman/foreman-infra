def versions = [
    'develop': [
        'branch': 'develop',
        'katello': 'master'
    ],
    '1.18': [
        'branch': '1.18-stable',
        'katello': 'KATELLO-3.7'
    ],
    '1.17': [
        'branch': '1.17-stable',
        'katello': 'KATELLO-3.6'
    ],
    '1.16': [
        'branch': '1.16-stable',
        'katello': 'KATELLO-3.5'
    ]
]

def foremanVersion(katelloVersion) {
    return versions.find { it.value['katello'] == katelloVersion }.key
}
