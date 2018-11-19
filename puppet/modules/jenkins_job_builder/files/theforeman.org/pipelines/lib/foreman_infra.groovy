void git_clone_foreman_infra(args = [:]) {
    target_dir = args.target_dir ?: ''

    dir(target_dir) {
        git url: 'https://github.com/theforeman/foreman-infra'
    }
}

def set_job_build_description() {
    def build_description = ""
    def files_list = sh(script: "ls jobs/ -1", returnStdout: true).trim().split()

    for (i = 0; i < files_list.size(); i++) {
       link = readFile("jobs/${files_list[i]}")
       build_description += "<a href=\"${link}\">${files_list[i]}</a><br/>"
    }

    currentBuild.description = build_description
}
