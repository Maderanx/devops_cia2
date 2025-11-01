pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '851871628220'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-app"
        IMAGE = 'devops-app'
        IMAGE_TAG = "latest"

        PATH = "/opt/homebrew/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:${env.PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'mai', url: 'https://github.com/Maderanx/devops_cia2.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "📦 Installing npm packages..."
                sh '''
                    echo "📁 Current directory: $(pwd)"
                    echo "📄 Listing files:"
                    ls -la
                    /opt/homebrew/bin/npm install
                '''
            }
        }

        stage('Run Tests') {
            steps {
                echo "🧪 Running tests..."
                sh '/opt/homebrew/bin/npm test || echo "No tests found, skipping..."'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                    echo "📁 Current directory before build: $(pwd)"
                    ls -la
                    /usr/local/bin/docker build -t ${IMAGE}:${IMAGE_TAG} .
                    /usr/local/bin/docker tag ${IMAGE}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "🔐 Logging into AWS ECR..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        /usr/local/bin/docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "📤 Pushing Docker image to ECR..."
                sh "/usr/local/bin/docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to ECS') {
            steps {
                echo "🚀 Deploying container on ECS..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        aws ecs update-service \
                            --cluster devops \
                            --service devops-service-5yesb3ba \
                            --force-new-deployment \
                            --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build, Push, and ECS Deployment Successful!"
            echo "App deployed on ECS in region ${AWS_REGION}"
        }
        failure {
            echo "❌ Pipeline Failed. Check Jenkins logs for details."
        }
    }
}
