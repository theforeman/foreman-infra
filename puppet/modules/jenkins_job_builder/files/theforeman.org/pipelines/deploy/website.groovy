pipeline {
    agent { label 'admin && sshkey' }

    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '3'))
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        ruby_version = '2.5'
        // Sync to the pivot-point on the web node
        target_path = 'website@web01.osuosl.theforeman.org:rsync_cache/'
    }

    stages {
        stage('Deploy website') {
            steps {
                git url: 'https://github.com/theforeman/theforeman.org', branch: 'gh-pages'

                script {
                    try {
                        configureRVM(ruby_version)
                        withRVM(['bundle install --jobs=5 --retry=5'], ruby_version)
                        withRVM(['bundle exec jekyll build'], ruby_version)
                    } finally {
                        cleanupRVM(ruby_version)
                    }
                }

                sshagent(['deploy-website']) {
                    // Copy the site to the web node
                    // Dependencies
                    // * the web node must have the web class
                    sh "/usr/bin/rsync --archive --checksum --verbose --one-file-system --compress --stats --delete-after ./_site/ ${target_path}"
                }
            }
        }
    }
}
