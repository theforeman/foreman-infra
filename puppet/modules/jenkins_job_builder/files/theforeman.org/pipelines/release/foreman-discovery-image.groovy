pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Run FDI build') {
            steps {
                deleteDir()
                dir('build') {
                    script {
                        job_parameters = [
                            proxy_repository: env.proxy_repository,
                            branch: env.branch,
                        ]
                        job_extra_vars = [
                            jenkins_download_artifacts: 'true',
                            jenkins_artifacts_directory: "${env.WORKSPACE}/artifacts/",
                        ]
                        runCicoJob("foreman-discovery-image-build", job_parameters, job_extra_vars)
                    }
                }
            }
        }

        stage('Prepare FDI upload') {
            steps {
                dir('result') {
                    sh """
                    mv ../artifacts/fdi*tar .
                    mv ../artifacts/fdi*iso .
                    ln -snf fdi*tar fdi-image-latest.tar
                    md5sum fdi*tar fdi*iso > MD5SUMS
                    """
                }
            }
        }

        stage('Publish FDI build') {
            steps {
                script {
                    base_dir = "/var/www/vhosts/downloads/htdocs/discovery"
                    destination_user = 'root'
                    destination_server = 'web02.theforeman.org'
                    destination_dir = "${base_dir}/${output_dir}"

                    sshagent(['deploy-downloads']) {
                        // publish on web
                        sh "rsync --recursive --links --times --verbose --delete result/ ${destination_user}@${destination_server}:${destination_dir}/"

                        // create symlinks
                        sh "ssh ${destination_user}@${destination_server} 'pushd ${base_dir}/releases/ && rm -f latest; ln -snf \$(ls -t | head -n 1) latest; popd' || true"
                    }

                    sh "curl --silent -X PURGE -H 'Fastly-Soft-Purge:1' https://downloads.theforeman.org/discovery/${output_dir}/fdi-image-latest.tar"
                }
            }
        }
    }

    post {
        cleanup {
            deleteDir()
        }
    }
}
