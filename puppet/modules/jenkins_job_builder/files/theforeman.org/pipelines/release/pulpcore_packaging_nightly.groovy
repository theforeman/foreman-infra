def packaging_branch = 'rpm/3.7'
def source_server = 'http://ah.testing.ansible.com/nightlies/latest/'

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 4, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Clone Packaging') {
            steps {
                checkout([
                    $class : 'GitSCM',
                    branches : [[name: "*/${packaging_branch}"]],
                    extensions: [[$class: 'CleanCheckout']],
                    userRemoteConfigs: [
                        [url: 'https://github.com/theforeman/pulpcore-packaging']
                    ]
                ])

            }
        }

        stage('Nightly Build Packages') {
            steps {
                setup_obal()

                script{

                    def response = sh returnStdout: true, script: "curl --silent ${source_server}/index.json"
                    def index = readJSON text: response

                    index.each { pkg, version ->
                        def (main_ver, dev_ver) = version.split('.dev')
                        obal(
                            action: 'update',
                            packages: "python-${pkg}",
                            extraVars: [
                                'version': main_ver,
                                'prerelease': "dev${dev_ver}",
                                'source_server': source_server,
                            ]
                        )
                        obal(
                            action: 'scratch',
                            packages: "python-${pkg}"
                        )
                    }
                }

            }
        }
    }

    post {
        failure {
            notifyDiscourse(
              env,
              "${env.JOB_NAME} failed",
              "pulpcore packaging nightly job failed: ${env.BUILD_URL}"
            )
        }
    }
}
