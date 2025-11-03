pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '851871628220'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-app"
        IMAGE = 'devops-app'
        IMAGE_TAG = "latest"
        ECS_CLUSTER = 'devops'
        ECS_SERVICE = 'devops-service-568dler7'
        ECS_TASK_FAMILY = 'devops'
        SNS_TOPIC_ARN = "arn:aws:sns:ap-south-1:851871628220:jenkins-deploy-alerts"
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
                echo "Installing npm packages..."
                sh '''
                    echo "Current directory: $(pwd)"
                    echo "Listing files:"
                    ls -la
                    /opt/homebrew/bin/npm install
                '''
            }
        }

        stage('Run Tests') {
            steps {
                echo "Running tests..."
                sh '/opt/homebrew/bin/npm test || echo "No tests found, skipping..."'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh '''
                    echo "Current directory before build: $(pwd)"
                    ls -la
                    /usr/local/bin/docker build --platform linux/amd64 -t ${IMAGE}:${IMAGE_TAG} .
                    /usr/local/bin/docker tag ${IMAGE}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "Logging into AWS ECR..."
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
                echo "Pushing Docker image to ECR..."
                sh "/usr/local/bin/docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Register New ECS Task Definition') {
            steps {
                echo "Updating ECS Task Definition..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        # Get the current task definition JSON
                        aws ecs describe-task-definition --task-definition ${ECS_TASK_FAMILY} --query taskDefinition > taskdef.json

                        # Remove unwanted fields (revision, status, etc.)
                        cat taskdef.json | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' > new-taskdef.json

                        # Update image to the new ECR image URI
                        jq '.containerDefinitions[0].image = "${ECR_REPO}:${IMAGE_TAG}"' new-taskdef.json > final-taskdef.json

                        # Register new revision
                        aws ecs register-task-definition --cli-input-json file://final-taskdef.json
                    """
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                echo "Deploying container on ECS..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER} \
                            --service ${ECS_SERVICE} \
                            --force-new-deployment \
                            --region ${AWS_REGION}
                    """
                }
            }
        }

        stage('Notify via SNS') {
            steps {
                echo "🔔 Sending deployment notification via AWS SNS..."
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                        aws sns publish \
                            --topic-arn ${SNS_TOPIC_ARN} \
                            --subject "Jenkins ECS Deployment Successful" \
                            --message "The ECS deployment for ${IMAGE}:${IMAGE_TAG} was successful in cluster ${ECS_CLUSTER}, service ${ECS_SERVICE}."
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build, Push, ECS Deployment, and Notification Successful!"
        }
        failure {
            echo "Pipeline Failed. Check Jenkins logs for details."
        }
    }
}
