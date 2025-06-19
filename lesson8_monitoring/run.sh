kubectl apply -f deployment_nginx.yaml
kubectl apply -f service_nginx.yaml
kubectl apply -f deployment_prom_exporter.yaml
kubectl apply -f service_prom_exporter.yaml
kubectl apply -f service_monitor.yaml