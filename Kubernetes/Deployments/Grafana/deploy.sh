#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="monitoring"

echo -e " \033[32;5mApplying core Kubernetes resources (Namespace and Secrets)...\033[0m"
kubectl apply -f namespace.yaml
kubectl apply -f grafana-admin.yaml
kubectl apply -f grafana-db.yaml

echo -e " \033[32;5mApplying 3-Replica Redis Deployment for HA Session Caching...\033[0m"
kubectl apply -f redis-deployment.yaml

echo -e " \033[32;5mApplying 3-Replica Grafana Deployment and Service (using Longhorn PVC)...\033[0m"
kubectl apply -f grafana-deployment.yaml

echo -e " \033[32;5mApplying Traefik Middleware and IngressRoute...\033[0m"
kubectl apply -f default-headers.yaml
kubectl apply -f ingress.yaml

echo -e " \033[32;5mWaiting for Grafana Pods to be ready...\033[0m"
kubectl wait --for=condition=Available deployment/grafana --timeout=300s -n "${NAMESPACE}"

echo -e "\n \033[32;5mScript finished. Grafana (HA) should be available via your IngressRoute.\033[0m"