def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Clone Packaging') {
            steps {

                deleteDir()
                ghprb_git_checkout()

            }
        }

        stage('Find Packages to Build') {
            steps {

                script {
                    changed_packages = sh(returnStdout: true, script: "git diff origin/${ghprbTargetBranch} --name-only --diff-filter=d -- 'packages/**.spec'").trim()

                    if (changed_packages) {
                        changed_packages = sh(returnStdout: true, script: "echo '${changed_packages}' | xargs dirname | xargs -n1 basename |sort -u").trim()
                    } else {
                        changed_packages = ''
                    }
                    packages_to_build = changed_packages.split().join(' ')
                    update_build_description_from_packages(packages_to_build)
                }

            }
        }

        stage('Scratch Build Packages') {
            when {
                expression { packages_to_build }
            }
            steps {

                obal(action: "scratch", extraVars: ['build_package_download_logs': 'True'], packages: packages_to_build)

            }
        }
    }

    post {
        always {
            status_koji_links("${currentBuild.getCurrentResult()}")
        }
    }
}

def status_koji_links(build_status) {
    def tasks = get_koji_tasks()
    for (String task: tasks) {
        githubNotify credentialsId: 'github-token', account: 'theforeman', repo: 'foreman-packaging', sha: "${ghprbActualCommit}", context: "koji/${task}", description: "koji task #${task}" , status: build_status, targetUrl: "http://koji.katello.org/koji/taskinfo?taskID=${task}"
    }
}

def get_koji_tasks() {
    def tasks = []
    if(fileExists('kojilogs')) {
        tasks = sh(returnStdout: true, script: "ls kojilogs -1 |grep -o '[0-9]*\$'").trim().split()
    }
    return tasks
}

def update_build_description_from_packages(packages_to_build) {
    build_description = "${packages_to_build}"
    currentBuild.description = build_description
}
