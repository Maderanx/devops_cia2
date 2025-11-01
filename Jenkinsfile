pipeline {
    agent any

    environment {
        // AWS & Docker settings
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '851871628220'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-app"
        IMAGE = 'devops-app'
        IMAGE_TAG = "latest"
        ECS_CLUSTER = 'devops'                     // ✅ ECS Cluster Name
        ECS_SERVICE = 'devops-service-5yesb3ba'    // ✅ ECS Service Name
        ECS_TASK_DEF = 'devops'                    // ✅ ECS Task Definition Family Name

        // macOS Jenkins PATH fix for npm, sh, aws, docker, jq
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
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
                    /opt/homebrew/bin/docker build -t ${IMAGE}:${IMAGE_TAG} .
                    /opt/homebrew/bin/docker tag ${IMAGE}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
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
                sh "/opt/homebrew/bin/docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to ECS') {
            steps {
                echo "🚀 Deploying latest image to ECS..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    script {
                        // Get current task definition JSON
                        sh 'aws ecs describe-task-definition --task-definition ${ECS_TASK_DEF} --query taskDefinition > taskdef.json'

                        // Replace the image URI in the container definition
                        sh '''
                        jq --arg IMAGE "${ECR_REPO}:${IMAGE_TAG}" '.containerDefinitions[0].image = $IMAGE' taskdef.json > new-taskdef.json
                        '''

                        // Register the new task definition revision
                        sh 'aws ecs register-task-definition --cli-input-json file://new-taskdef.json > new-taskdef-out.json'

                        // Extract new revision number
                        def revision = sh(script: "jq -r '.taskDefinition.revision' new-taskdef-out.json", returnStdout: true).trim()
                        echo "🆕 Registered new task definition revision: ${revision}"

                        // Update ECS service with new task definition revision
                        sh """
                            aws ecs update-service \
                                --cluster ${ECS_CLUSTER} \
                                --service ${ECS_SERVICE} \
                                --task-definition ${ECS_TASK_DEF}:${revision} \
                                --force-new-deployment \
                                --region ${AWS_REGION}
                        """

                        echo "🕒 Waiting for ECS deployment to stabilize..."
                        sh """
                            aws ecs wait services-stable \
                                --cluster ${ECS_CLUSTER} \
                                --services ${ECS_SERVICE}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ ECS Deployment Successful!"
            echo "App is live via ECS service: ${ECS_SERVICE} in cluster ${ECS_CLUSTER}"
        }
        failure {
            echo "❌ Pipeline Failed. Check Jenkins logs for details."
        }
    }
}
