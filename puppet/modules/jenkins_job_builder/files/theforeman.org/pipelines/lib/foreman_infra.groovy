void git_clone_foreman_infra(args = [:]) {
    target_dir = args.target_dir ?: ''

    dir(target_dir) {
        git url: 'https://github.com/theforeman/foreman-infra', poll: false
    }
}

def list_files(glob = '') {
    sh(script: "ls -1 ${glob}", returnStdout: true).trim().split()
}

def set_job_build_description(job_name) {
    def build_description = ""
    def file_name = "jobs/${job_name}"

    if (fileExists(file_name)) {
       link = readFile(file_name)
       build_description += "<a href=\"${link}\">${job_name}</a><br/>"
    }

    if (currentBuild.description == null) {
        currentBuild.description = ''
    }

    currentBuild.description += build_description
}
