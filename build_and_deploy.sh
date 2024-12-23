#!/bin/bash

# Exit immediately if a command fails
set -e

# Define variables
LOCAL_REGISTRY="localhost:5000"
BACKEND_DIR="./UniTrackRemasterBackend"
FRONTEND_DIR="./UniTrackRemasterFrontend"
BACKEND_IMAGE_NAME="unitrack-backend"
FRONTEND_IMAGE_NAME="unitrack-frontend"
STACK_FILE="docker-compose.yml"
STACK_NAME="unitrack-stack"

# checking if the container is running, prevents issues with replicas exceeding limit
is_container_running() {
  docker ps --filter "name=$1" --filter "status=running" -q
}

# Step 1: Check and Start Docker Registry, using a local one because I don't want to pay github
echo "Checking if local Docker registry is running..."
if [[ $(is_container_running "registry") ]]; then
  echo "Local Docker registry is already running."
else
  echo "Starting local Docker registry..."
  docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi

# Step 2: Build and Push Backend Image
echo "Building backend image..."
if [[ -f "$BACKEND_DIR/Dockerfile" ]]; then
  docker build -t $LOCAL_REGISTRY/$BACKEND_IMAGE_NAME $BACKEND_DIR
  echo "Pushing backend image to local registry..."
  docker push $LOCAL_REGISTRY/$BACKEND_IMAGE_NAME
else
  echo "Error: Dockerfile not found in $BACKEND_DIR"
  exit 1
fi

# Step 3: Build and Push Frontend Image
echo "Building frontend image..."
if [[ -f "$FRONTEND_DIR/Dockerfile" ]]; then
  docker build -t $LOCAL_REGISTRY/$FRONTEND_IMAGE_NAME $FRONTEND_DIR
  echo "Pushing frontend image to local registry..."
  docker push $LOCAL_REGISTRY/$FRONTEND_IMAGE_NAME
else
  echo "Error: Dockerfile not found in $FRONTEND_DIR"
  exit 1
fi

# Step 4: Deploy the Docker Stack
echo "Deploying the stack..."
docker stack deploy -c $STACK_FILE $STACK_NAME

# Step 5: Verify Deployment
echo "Verifying deployment..."
docker stack services $STACK_NAME

echo "Deployment complete!"
echo "Access your frontend via http://<your-machine-ip>"
echo "Access Prometheus via http://<your-machine-ip>:9090"
echo "Access Grafana via http://<your-machine-ip>:3001"
