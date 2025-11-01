#!/bin/bash
# ===========================
# Fetch latest ECS task public IP
# ===========================

# ---- CONFIGURE THESE ----
CLUSTER_NAME="devops"
SERVICE_NAME="devops-service-568dler7"
REGION="ap-south-1"
# --------------------------

echo "🔍 Fetching latest running task for service: $SERVICE_NAME..."

# Get the latest running task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --desired-status RUNNING \
  --region "$REGION" \
  --query 'taskArns[-1]' \
  --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "❌ No running tasks found!"
  exit 1
fi

echo "✅ Found task: $TASK_ARN"
echo "🌐 Fetching ENI (Elastic Network Interface) ID..."

# Extract the ENI ID from the task description
ENI_ID=$(aws ecs describe-tasks \
  --cluster "$CLUSTER_NAME" \
  --tasks "$TASK_ARN" \
  --region "$REGION" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId']|[0].value" \
  --output text)

if [ -z "$ENI_ID" ]; then
  echo "❌ Could not retrieve ENI ID."
  exit 1
fi

echo "✅ ENI ID: $ENI_ID"

# Get the public IP from the ENI
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids "$ENI_ID" \
  --region "$REGION" \
  --query "NetworkInterfaces[0].Association.PublicIp" \
  --output text)

if [ "$PUBLIC_IP" == "None" ] || [ -z "$PUBLIC_IP" ]; then
  echo "❌ No public IP found (task might not have public networking)."
  exit 1
fi

echo ""
echo "🌎 Latest ECS task public IP: $PUBLIC_IP"
echo "➡️  Access your app at: http://$PUBLIC_IP:8080"
