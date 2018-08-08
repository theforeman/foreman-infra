def provision() {
    fix_ansible_config()

    dir('foreman-infra') {
        git url: 'https://github.com/theforeman/foreman-infra.git'
    }

  	dir('foreman-infra/ci/centos.org/ansible') {
        runPlaybook(playbook: 'provision.yml')
    }
}

def fix_ansible_config() {
    sh "sed -i s/yaml/debug/g ansible.cfg"
}

def deprovision() {
    if (fileExists('foreman-infra')) {
        dir('foreman-infra/ci/centos.org/ansible') {
            runPlaybook(playbook: 'deprovision.yml')
      	}
    }
}

def cico_inventory(relative_dir = '') {
    return relative_dir + 'foreman-infra/ci/centos.org/ansible/cico_inventory'
}

def ssh_config(relative_dir = '') {
    return relative_dir + 'foreman-infra/ci/centos.org/ansible/ssh_config'
}

def color_shell(command = '') {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "${command}"
    }
}

def duffy_ssh(command, box_name, relative_dir = '') {
    color_shell "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -F ${ssh_config(relative_dir)} ${box_name} '${command}'"
}

def duffy_scp(file_path, file_dest, box_name, relative_dir = '') {
    color_shell "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r -F ${ssh_config(relative_dir)} ${box_name}:${file_path} ${file_dest}"
}
