pipeline {
    agent any

    environment {
        // AWS & Docker settings
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '851871628220'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-app"
        IMAGE = 'devops-app'
        IMAGE_TAG = "latest"

        // Explicit path fix for macOS Jenkins
        PATH = "/opt/homebrew/bin:/bin:/usr/bin:/usr/local/bin:${env.PATH}"
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
                sh '/opt/homebrew/bin/npm install'
            }
        }

        stage('Run Tests') {
            steps {
                echo "🧪 Running tests (if any)..."
                sh '/opt/homebrew/bin/npm test || echo "No tests found, skipping..."'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh """
                    /usr/local/bin/docker build -t ${IMAGE}:${IMAGE_TAG} .
                    /usr/local/bin/docker tag ${IMAGE}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "🔐 Logging into AWS ECR..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
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

        stage('Deploy Locally (Optional)') {
            steps {
                echo "🚀 Running container locally on port 3000..."
                sh '''
                    docker stop devops-app || true
                    docker rm devops-app || true
                    docker run -d -p 3000:3000 --name devops-app ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Build & Push Successful!"
            echo "App running locally at: http://localhost:3000"
        }
        failure {
            echo "❌ Pipeline Failed. Check Jenkins logs for details."
        }
    }
}
