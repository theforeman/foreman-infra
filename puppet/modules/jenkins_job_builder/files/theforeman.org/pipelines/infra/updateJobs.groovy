pipeline {
    agent { label 'fast' }

    stages {
        stage('Setup workspace') {
            steps {
                checkout([
                    $class : 'GitSCM',
                    branches : [[name: 'update_jobs']],
                    extensions: [[$class: 'CleanCheckout']],
                    userRemoteConfigs: [
                        [url: 'https://github.com/theforeman/foreman-infra.git']
                    ]
                ])

                virtEnv('./ci', 'pip install jenkins-job-builder')
            }
        }

        stage('Update ci.centos.org jobs') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-centos', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
                    virtEnv('./ci', "cd ./centos.org && jenkins-jobs --conf ./centos_jenkins.ini --user '${env.USERNAME}' --password '${env.PASSWORD}' update -r ./jobs")
                }
            }
        }
    }

    post {
        always {
            script {
                if(fileExists('ci/update_jobs')) {
                    dir('ci/update_jobs') {
                        deleteDir()
                    }
                }
            }
        }
    }
}
