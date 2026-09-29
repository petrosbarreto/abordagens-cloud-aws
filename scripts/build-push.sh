#!/bin/bash
# Lab 3 (parte A) — rode na EC2 do Lab 1, via EC2 Instance Connect:
#   bash /opt/app/scripts/build-push.sh
# A instância usa o LabInstanceProfile, que já tem permissão de ECR.
set -euo pipefail

export AWS_DEFAULT_REGION=us-east-1
REPO_NAME=abordagens
TAG=v1

sudo dnf install -y docker
sudo systemctl start docker

cd /opt/app

aws ecr describe-repositories --repository-names "$REPO_NAME" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO_NAME" >/dev/null

ACC=$(aws sts get-caller-identity --query Account --output text)
REG="$ACC.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

aws ecr get-login-password | sudo docker login -u AWS --password-stdin "$REG"
sudo docker build -t "$REG/$REPO_NAME:$TAG" .
sudo docker push "$REG/$REPO_NAME:$TAG"

echo
echo "URI da imagem (use na task definition do ECS):"
echo "  $REG/$REPO_NAME:$TAG"
