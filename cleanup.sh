#!/bin/bash
echo "=== Cleaning up Kubernetes Demo ==="

kubectl delete -f k8s/ --ignore-not-found
echo ""
echo "Resources deleted. To also stop minikube:"
echo "  minikube stop"
