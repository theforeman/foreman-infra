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
                script {
                    job_parameters = [
                        proxy_repository: env.proxy_repository,
                        repoowner: env.repoowner,
                        branch: env.branch,
                    ]
                    runCicoJob("foreman-discovery-image-build", job_parameters)
                }
            }
        }

        stage('Publish FDI build') {
            steps {
                script {
                    destination_user = 'root'
                    destination_server = 'web02.theforeman.org'
                    base_dir = "/var/www/vhosts/downloads/htdocs/discovery"

                    sshagent(['deploy-downloads']) {
                        // delete old files in the target folder
                        sh "ssh ${destination_user}@${destination_server} 'mkdir -p ${base_dir}/${output_dir}/ ; rm -f ${base_dir}/${output_dir}/*' || true"

                        // publish on web
                        sh "scp fdi*tar fdi*iso ${destination_user}@${destination_server}:${base_dir}/${output_dir}/"

                        // create symlinks
                        sh "ssh ${destination_user}@${destination_server} 'pushd ${base_dir}/releases/ && rm -f latest; ln -snf \$(ls -t | head -n 1) latest; popd' || true"
                        sh "ssh ${destination_user}@${destination_server} 'pushd ${base_dir}/${output_dir}/ && ln -sf fdi*tar fdi-image-latest.tar && popd' || true"

                        // create sums
                        sh "ssh ${destination_user}@${destination_server} 'pushd ${base_dir}/${output_dir}/ && md5sum * > MD5SUMS; popd' || true"
                    }
                }
            }
        }
    }
}
