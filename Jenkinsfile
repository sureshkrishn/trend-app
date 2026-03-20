pipeline {
    agent any

    environment {
        IMAGE_NAME = "sureshkrishn/trend-app"
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "trend-cluster"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                sh "docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest"
            }
        }

        stage('Login & Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Configure EKS Access') {
            steps {
                sh '''
                aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                kubectl set image deployment/trend-app trend-container=${IMAGE_NAME}:${BUILD_NUMBER}
                kubectl rollout status deployment/trend-app --timeout=300s
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Successfully deployed to EKS!"
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
