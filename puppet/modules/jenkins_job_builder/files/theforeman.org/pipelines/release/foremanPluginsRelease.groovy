def versions = [
    "nightly": ["el7": "RHEL/7"],
    "1.23": ["el7": "RHEL/7"],
    "1.22": ["el7": "RHEL/7"],
    "1.21": ["el7": "RHEL/7"],
]

pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            steps {

                mash("foreman-mash-split-plugins.py")

            }
        }
        stage('Repoclosures') {
            steps {
                script {
                    results = repoclosures('plugins', versions)
                }
            }
        }
        stage('push-rpms') {
            steps {
                git_clone_foreman_infra()
                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                }
                script {
                    def pushVersions = [:]
                    versions.each { version, distros ->
                        distros.each { distro, os ->
                            pushVersions["push-${version}-${distro}"] = {
                                script {
                                    if (results["${version}-${distro}"] == true) {
                                        dir('deploy') {
                                            push_rpms_direct("foreman-plugins-${version}/${os}", "plugins/${version}/${distro}", false, true)
                                        }
                                    } else {
                                        echo "${version} ${distro} repoclosure failed: ${results[version]}"
                                        throw results["${version}-${distro}"]
                                    }
                                }
                            }
                        }
                    }

                    parallel pushVersions
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
