#!/bin/bash
#
# Kubernetes Deployment Script for LMS Platform
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE="lms-production"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}LMS Kubernetes Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${YELLOW}Deploying to namespace: ${NAMESPACE}${NC}"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"

# Create secrets (must exist before this runs)
if [ ! -f "${SCRIPT_DIR}/secrets.yaml" ]; then
    echo -e "${RED}Error: secrets.yaml not found${NC}"
    echo "Create it from secrets.yaml.example and add your actual secrets"
    exit 1
fi

# Apply configurations
echo "Applying ConfigMaps..."
kubectl apply -f "${SCRIPT_DIR}/configmap.yaml"

echo "Applying Secrets..."
kubectl apply -f "${SCRIPT_DIR}/secrets.yaml"

# Deploy databases
echo "Deploying PostgreSQL..."
kubectl apply -f "${SCRIPT_DIR}/postgres-deployment.yaml"

echo "Deploying Redis..."
kubectl apply -f "${SCRIPT_DIR}/redis-deployment.yaml"

# Wait for databases to be ready
echo "Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE} --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n ${NAMESPACE} --timeout=60s

# Deploy backend
echo "Deploying backend..."
kubectl apply -f "${SCRIPT_DIR}/backend-deployment.yaml"

# Deploy Celery workers
echo "Deploying Celery workers..."
kubectl apply -f "${SCRIPT_DIR}/celery-deployment.yaml"

# Deploy ingress
echo "Deploying ingress..."
kubectl apply -f "${SCRIPT_DIR}/ingress.yaml"

# Wait for backend rollout
echo "Waiting for backend rollout..."
kubectl rollout status deployment/backend -n ${NAMESPACE}

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "View resources:"
echo "  kubectl get all -n ${NAMESPACE}"
echo ""
echo "View logs:"
echo "  kubectl logs -f deployment/backend -n ${NAMESPACE}"
echo ""
echo "Check pod status:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
