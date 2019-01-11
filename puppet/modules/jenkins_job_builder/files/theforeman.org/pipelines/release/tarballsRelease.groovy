pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    environment {
        version = env.getProperty('version')
        major_version = env.getProperty('major_version')
        ruby_ver = '2.5'
    }

    stages {
        stage('Parallel') {

            parallel {
                stage('Foreman') {
                    steps {
                        verify_tag('foreman', version)
                        build_tarball('foreman', version, ruby_ver)
                    }
                }
                stage('Smart Proxy') {
                    steps {
                        verify_tag('smart-proxy', version)
                        build_tarball('smart-proxy', version, ruby_ver)
                    }
                }
                stage('Foreman SELinux') {
                    steps {
                        verify_tag('foreman-selinux', version)
                        build_tarball('foreman-selinux', version, ruby_ver)
                    }
                }
                stage('Foreman Installer') {
                    steps {
                        verify_tag('foreman-installer', version)
                        build_tarball('foreman-installer', version, ruby_ver)
                    }
                }
            }
        }
    }
}

void verify_tag(project, version) {
    dir(project) {
        git url: "https://github.com/theforeman/${project}.git", branch: 'develop', poll: false
        sh "git tag -l ${version} | grep ${version}"
    }
}

void build_tarball(project, version, ruby_ver) {
    def base_dir = "/var/www/vhosts/downloads/htdocs/${project}"
    def rake = "rake"

    dir(project) {
        checkout scm: [$class: 'GitSCM',
            userRemoteConfigs: [[url: "https://github.com/theforeman/${project}.git"]],
            branches: [[name: "refs/tags/${version}"]],
            extensions: [[$class: 'CleanCheckout']]],
            changelog: false,
            poll: false

        configureRVM(ruby_ver, project)

        if (project == 'foreman') {
            sh "cat config/settings.yaml.example > config/settings.yaml"
            sh "cat config/database.yml.example > config/database.yml"
        }

        env.setProperty('DEBUG_RESOLVER', '1')

        if (fileExists("Gemfile")) {
            withRVM(["bundle install --without=development --jobs=5 --retry=5"], ruby_ver, project)
            rake = "bundle exec rake"
        }

        withRVM(["${rake} pkg:generate_source"], ruby_ver, project)

        sh "ssh root@theforeman.org \"mkdir -p ${base_dir}/\" || true"
        sh "rsync -v --ignore-existing pkg/* root@theforeman.org:${base_dir}/"

        cleanupRVM(ruby_ver, project)
    }
}
