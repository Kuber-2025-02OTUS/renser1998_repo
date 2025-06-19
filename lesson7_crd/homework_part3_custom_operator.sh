#!/bin/bash
kubectl delete -f mysql-instance.yaml
kubectl delete -f crd-op-deployment.yaml

kubectl apply -f crd.yaml
kubectl apply -f mysql-instance.yaml
python3 -m venv venv 
source 
echo "Resources removed and recreated successfully."