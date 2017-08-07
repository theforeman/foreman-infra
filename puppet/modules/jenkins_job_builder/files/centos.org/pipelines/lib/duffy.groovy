def provision() {
    dir('foreman-infra') {
        git url: 'https://github.com/ehelms/foreman-infra.git', branch: 'ci-centos-org'
    }

	dir('foreman-infra/puppet/modules/jenkins_job_builder/files/centos.org/ansible') {
        runPlaybook('provision.yml', 'localhost')
    }
}

def deprovision() {
	dir('foreman-infra/puppet/modules/jenkins_job_builder/files/centos.org/ansible') {
        runPlaybook('deprovision.yml', 'localhost')
    }
}

def cico_inventory(relative_dir = '') {
	return relative_dir + 'foreman-infra/puppet/modules/jenkins_job_builder/files/centos.org/ansible/cico_inventory'
}
