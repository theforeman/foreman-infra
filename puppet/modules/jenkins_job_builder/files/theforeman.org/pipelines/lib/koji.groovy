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
