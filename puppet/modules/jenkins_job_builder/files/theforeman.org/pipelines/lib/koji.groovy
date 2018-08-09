def status_koji_links(repo) {
    def tasks = get_koji_tasks()
    for (String task: tasks) {
        taskinfo = sh(returnStdout: true, script: "koji taskinfo -v ${task}").trim()
        taskinfo_yaml = readYaml text: taskinfo
        build_status = (taskinfo_yaml["State"] == 'failed') ? 'FAILURE' : 'SUCCESS'
        build_package = taskinfo_yaml["Request Parameters"]["Source"].split('/')[-1]
        githubNotify credentialsId: 'github-token', account: 'theforeman', repo: repo, sha: "${ghprbActualCommit}", context: "koji/${build_package}", description: "koji task #${task} for ${build_package}" , status: build_status, targetUrl: "http://koji.katello.org/koji/taskinfo?taskID=${task}"
    }
}

def get_koji_tasks() {
    def tasks = []
    if(fileExists('kojilogs')) {
        tasks = sh(returnStdout: true, script: "ls kojilogs -1 |grep -o '[0-9]*\$'").trim().split()
    }
    return tasks
}
