pipeline {
    agent { label 'admin && sshkey' }

    triggers {
        cron('H H * * *')
    }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            steps {

                sh "ssh -o 'BatchMode yes' root@koji.katello.org foreman-mash-split-plugins.py"

            }
        }
        stage('Repoclosure') {
            steps {

                parallel(
                    'nightly/el7': { repoclosure('nightly', 'el7') },
                    '1.16/el7': { repoclosure('1.16', 'el7') },
                    '1.15/el7': { repoclosure('1.15', 'el7') },
                    '1.15/f24': { repoclosure('1.15', 'f24') },
                    '1.14/el7': { repoclosure('1.14', 'el7') },
                    '1.14/f24': { repoclosure('1.14', 'f24') }
                )

            }
        }
        stage('Setup Push Environment') {
            steps {

                git url: 'https://github.com/theforeman/foreman-infra'
                dir('deploy') { withRVM(["bundle install"]) }
            }
        }
        stage('Push RPMs') {
            steps {

                parallel(
                    'nightly/el7': { repoclosure('nightly', 'el7') },
                    '1.16/el7': { repoclosure('1.16', 'el7') },
                    '1.15/el7': { repoclosure('1.15', 'el7') },
                    '1.15/f24': { repoclosure('1.15', 'f24') },
                    '1.14/el7': { repoclosure('1.14', 'el7') },
                    '1.14/f24': { repoclosure('1.14', 'f24') }
                )

            }
            post {
                always {
                    deleteDir()
                }
            }
        }
    }
}

void push_rpms(version, distro) {

    dir('deploy') {

        if (distro == 'el7') {
            withRVM(["cap yum repo:sync -S overwrite=false -S merge=true -S repo_source=foreman-plugins-${version}/RHEL/7 -S repo_dest=plugins/${version}/el7"])
        }

        if (distro == 'f24') {
            withRVM(["cap yum repo:sync -S overwrite=false -S merge=true -S repo_source=foreman-plugins-${version}/Fedora/24 -S repo_dest=plugins/${version}/f24"])
        }

    }

}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        def git_branch = (repo == 'nightly') ? 'develop' : repo

        git url: "http://github.com/theforeman/foreman-packaging", branch: "rpm/${git_branch}"

        def os_ver = 'RHEL/7'

        if (dist == 'f24') {
            os_ver = 'Fedora/24'
        }

        def command = [
            "./repoclosure.sh yum_${dist}.conf",
            "http://koji.katello.org/releases/yum/foreman-plugins-${repo}/${os_ver}/x86_64/",
            "-l ${dist}-foreman-${repo}",
            "-l ${dist}-base",
            "-l ${dist}-updates",
            "-l ${dist}-epel",
            "-l ${dist}-extras",
            "-l ${dist}-scl",
            "-l ${dist}-scl-sclo",
            "-l ${dist}-scl-ruby",
            "-l ${dist}-scl-v8",
            "-l ${dist}-puppet-4"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
