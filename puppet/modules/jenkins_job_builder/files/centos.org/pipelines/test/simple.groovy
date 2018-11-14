pipeline {
    agent { label 'foreman' }

    stages {
        stage('Echo') {
            steps {
                sh "echo"
            }
        }
    }
}
