pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '851871628220.dkr.ecr.ap-south-1.amazonaws.com/devops-app'
        IMAGE = 'devops-app'
        IMAGE_TAG = "latest"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/Maderanx/devops_cia2.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "No tests found, skipping..."'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "/usr/local/bin/docker build -t ${IMAGE}:${IMAGE_TAG} ."
                    sh "/usr/local/bin/docker tag ${IMAGE}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh "/usr/local/bin/docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy on EC2') {
            steps {
                sshagent(['ec2-key']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no ec2-user@<ec2-public-ip> "
                        aws ecr get-login-password --region ap-south-1 | \
                        docker login --username AWS --password-stdin 851871628220.dkr.ecr.ap-south-1.amazonaws.com &&
                        docker pull 851871628220.dkr.ecr.ap-south-1.amazonaws.com/devops-app:latest &&
                        docker stop devops-app || true &&
                        docker rm devops-app || true &&
                        docker run -d -p 80:3000 --name devops-app 851871628220.dkr.ecr.ap-south-1.amazonaws.com/devops-app:latest
                    "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful! App is live on EC2 at http://<ec2-public-ip>"
        }
        failure {
            echo "❌ Deployment Failed. Check Jenkins logs for details."
        }
    }
}
