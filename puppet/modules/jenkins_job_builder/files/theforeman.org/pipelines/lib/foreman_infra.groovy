void git_clone_foreman_infra(args = [:]) {
    target_dir = args.target_dir ?: ''

    dir(target_dir) {
        git url: 'https://github.com/theforeman/foreman-infra', poll: false
    }
}

def list_files(glob = '') {
    sh(script: "ls -1 ${glob}", returnStdout: true).trim().split()
}

def set_job_build_description(job_name, status) {
    def build_description = ""
    def file_name = "jobs/${job_name}"

    if (fileExists(file_name)) {
       link = readFile(file_name)
       build_description += "<a href=\"${link}\">${job_name}</a> (${status})<br/>"
    }

    if (currentBuild.description == null) {
        currentBuild.description = ''
    }

    currentBuild.description += build_description
}

def runIndividualCicoJob(job_name, number = 0) {
    def status = 'unknown'
    sleep(number * 5) //See https://bugs.centos.org/view.php?id=14920
    try {
        withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
            runPlaybook(
                playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                extraVars: [
                    "jenkins_job_name": "${job_name}",
                    "jenkins_username": "foreman",
                    "jenkins_job_link_file": "${env.WORKSPACE}/jobs/${job_name}"
                ],
                sensitiveExtraVars: ["jenkins_password": "${env.PASSWORD}"]
            )
        }
        status = 'passed'
    } catch(Exception ex) {
        status = 'failed'
        throw ex
    } finally {
        script {
            set_job_build_description(job_name, status)
        }
    }
}

def runCicoJob(job_name) {
    node('el') {
        script {
            git_clone_foreman_infra()
            try {
                runIndividualCicoJob(job_name)
            } finally {
                deleteDir()
            }
        }
    }
}

def runCicoJobsInParallel(jobs) {
    def branches = [:]
    for (int i = 0; i < jobs.size(); i++) {
        def index = i // fresh variable per iteration; i will be mutated
        branches[jobs[index]['name']] = {
            runIndividualCicoJob(jobs[index]['job'], index)
        }
    }

    node('el') {
        script {
            git_clone_foreman_infra()
            try {
                parallel branches
            } finally {
                deleteDir()
            }
        }
    }
}

def notifyDiscourse(env, introText, description) {
    emailext(
        subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
        to: 'ci@community.theforeman.org',
        body: [introText, env.BUILD_URL, description].minus(null).join('\n\n')
    )
}
