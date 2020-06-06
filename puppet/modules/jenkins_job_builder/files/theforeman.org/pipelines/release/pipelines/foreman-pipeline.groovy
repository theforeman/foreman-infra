pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {
                mash("foreman", foreman_version)
            }
        }
        stage('Mash Rails Koji Repositories') {
            agent { label 'sshkey' }

            when {
                expression { foreman_version == '1.24' }
            }
            steps {
                mash("foreman-rails", foreman_version)
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    parallel repoclosures('foreman', foreman_el_releases, foreman_version)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Install Test') {
            agent { label 'el' }

            steps {
                script {
                    def pipelines = foreman_server_distros.collect { os ->
                        [
                            name: os,
                            job: "foreman-${foreman_version}-${os}-release-test",
                            parameters: [
                                expected_version: params.expected_version
                            ]
                        ]
                    }

                    runCicoJobsInParallel(pipelines)
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git_clone_foreman_infra()

                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])

                    script {
                        if (foreman_version == '1.24') {
                            push_rpms_direct("foreman-rails-${foreman_version}/el7", "rails/foreman-${foreman_version}/el7", false, true)
                        }

                        for (release in foreman_el_releases) {
                            push_rpms_direct("foreman-${foreman_version}/RHEL/${release.replace('el', '')}", "releases/${foreman_version}/${release}", false, true)
                        }
                    }
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Push DEBs') {
            agent { label 'debian' }

            steps {
                script {
                    def pushDistros = [:]
                    foreman_debian_releases.each { distro ->
                        pushDistros["push-${foreman_version}-${distro}"] = {
                            script {
                                push_debs_direct(distro, foreman_version)
                            }
                        }
                    }

                    parallel pushDistros
                }
            }
        }
    }
}
