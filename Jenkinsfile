pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-creds')
        IMAGE_NAME = "sureshkrishn/trend-app"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:\${BUILD_NUMBER} ."
                    sh "docker tag ${IMAGE_NAME}:\${BUILD_NUMBER} ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Login and Push') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                kubectl set image deployment/trend-app trend-container=sureshkrishn/trend-app:latest
                kubectl rollout status deployment/trend-app --timeout=300s
                '''
            }
        }
    }
    
    post {
        success {
            echo "Successfully deployed to EKS!"
        }
        failure {
            echo "Pipeline failed."
        }
    }
}
