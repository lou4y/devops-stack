#!/bin/bash

# Function to apply YAML files in a directory
apply_yamls() {
  local dir=$1
  for file in "$dir"/*.yaml; do
    kubectl apply -f "$file"
  done
}

# Create Jenkins namespace and apply YAML files
echo "Creating Jenkins namespace and applying YAML files..."
kubectl create namespace jenkins
apply_yamls ./jenkins

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Update ArgoCD service to LoadBalancer
echo "Updating ArgoCD service to LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for services to be ready and get their IPs
echo "Waiting for Jenkins and ArgoCD services to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/jenkins -n jenkins
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD initial admin password
echo "Fetching ArgoCD initial admin password..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)

# Get Jenkins and ArgoCD service IPs
JENKINS_IP=$(kubectl get svc jenkins -n jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Display results
echo "ArgoCD initial admin password: $ARGOCD_PASSWORD"
echo "Jenkins service IP: $JENKINS_IP"
echo "ArgoCD server IP: $ARGOCD_IP"

