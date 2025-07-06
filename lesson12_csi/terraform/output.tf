output "cluster_id" {
  value = yandex_kubernetes_cluster.k8s-cluster.id
}

output "storage_bucket_name" {
  value = yandex_storage_bucket.s3-bucket.bucket
}
output "kubeconfig_command" {
  value = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.k8s-cluster.name} --external"
}
output "eso_service_account_key" {
  value = local_file.k8s-service-account-eso-key-file.filename
}
output "yandex_vpc_address_ip" {
  value = yandex_vpc_address.ip-otus-kuber-prod-k8s.external_ipv4_address[0].address 
}
output "registry_id" {
  value = yandex_container_registry.yandex-registry.id
}