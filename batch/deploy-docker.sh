#!/bin/bash
set -e
ACCOUNT=$(aws sts get-caller-identity --query Account --output text) # AWS ACCOUNT ID
DOCKER_CONTAINER=logan-cluster-job-$(uname -m)
REPO=${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${DOCKER_CONTAINER}
TAG=build-$(date -u "+%Y-%m-%d")
echo "Building Docker Image..."
#NOCACHE=--no-cache
docker build $NOCACHE -t $DOCKER_CONTAINER .

#echo "Authenticating against AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com
# create repository (only needed the first time)
aws ecr create-repository --repository-name $DOCKER_CONTAINER ||true
echo "Tagging ${REPO}..."
docker tag $DOCKER_CONTAINER:latest $REPO:$TAG
docker tag $DOCKER_CONTAINER:latest $REPO:latest
echo "Deploying to AWS ECR"
docker push $REPO
