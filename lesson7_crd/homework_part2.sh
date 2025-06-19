#!/bin/bash
kubectl delete -f mysql-instance.yaml
kubectl delete -f crd-op-deployment.yaml
kubectl apply -f crd.yaml
kubectl apply -f sa-cr-crb-crd_minimized.yaml
kubectl apply -f crd-op-deployment.yaml
kubectl apply -f mysql-instance.yaml
echo "Resources removed and recreated successfully."