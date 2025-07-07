terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# VPC
resource "yandex_vpc_network" "k8s-net" {
  name = "k8s-network-homework"
}

resource "yandex_vpc_subnet" "k8s-subnet" {
  name           = "k8s-subnet-homework"
  zone           = var.zone
  network_id     = yandex_vpc_network.k8s-net.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

# Сервисный аккаунт
resource "yandex_iam_service_account" "k8s-sa" {
  name = "k8s-service-account-homework"
}
resource "yandex_iam_service_account" "k8s-s3-storage" {
  name        = "k8s-service-account-s3-storage-homework"
  description = "Доступ к S3 хранилищу"
}
# Назначение ролей
resource "yandex_resourcemanager_folder_iam_member" "k8s-admin" {
  folder_id = var.folder_id
  role      = "k8s.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "vpc-admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "s3-storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-s3-storage.id}"
  
} 
#=================== SA storage static key ==================#
resource "yandex_iam_service_account_static_access_key" "k8s-s3-storage-key" {
  service_account_id = yandex_iam_service_account.k8s-s3-storage.id
  description        = "Static access key for k8s service account to access S3 storage"
}


#================== Node group SA====================#
resource "yandex_iam_service_account" "k8s-service-account-node-group" {
  name        = "k8s-service-account-node-group-homework"
  description = "Доступ к Docker-реестру"
}

resource "yandex_resourcemanager_folder_iam_member" "puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member = "serviceAccount:${yandex_iam_service_account.k8s-service-account-node-group.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member = "serviceAccount:${yandex_iam_service_account.k8s-service-account-node-group.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "storage-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member = "serviceAccount:${yandex_iam_service_account.k8s-service-account-node-group.id}"
}

resource "local_file" "sa_key" {
  content  =  jsonencode({
    access_key =yandex_iam_service_account_static_access_key.k8s-s3-storage-key.access_key,
    secret_key =  yandex_iam_service_account_static_access_key.k8s-s3-storage-key.secret_key
  })
  filename = "${path.module}/sa_key.json"
  
}
# ================ S3 Storage ==================#
resource "yandex_storage_bucket" "s3-bucket" {
  access_key            = yandex_iam_service_account_static_access_key.k8s-s3-storage-key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.k8s-s3-storage-key.secret_key
  bucket                = "k8s-s3-bucket-${var.folder_id}"
  max_size              = "5368709120"
  default_storage_class = "standard"
  folder_id = var.folder_id
  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
}
# Kubernetes Cluster
resource "yandex_kubernetes_cluster" "k8s-cluster" {
  name       = "k8s-cluster-homework"
  network_id = yandex_vpc_network.k8s-net.id
  master {
    public_ip = true
    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet.id
    }
  }

  service_account_id      = yandex_iam_service_account.k8s-sa.id
  node_service_account_id = yandex_iam_service_account.k8s-service-account-node-group.id
  release_channel         = "STABLE"
  depends_on = [ 
    yandex_resourcemanager_folder_iam_member.k8s-admin,
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.load-balancer-admin,
    yandex_resourcemanager_folder_iam_member.vpc-admin,
    yandex_iam_service_account.k8s-sa,
    yandex_iam_service_account.k8s-service-account-node-group
  ]
}

# Node Group
resource "yandex_kubernetes_node_group" "k8s-nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s-cluster.id
  name       = "k8s-node-group-homework"
  #version    = var.k8s_version

  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 50
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s-subnet.id]
      nat        = true
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }
  depends_on = [
    yandex_kubernetes_cluster.k8s-cluster,
    yandex_iam_service_account.k8s-sa,
    yandex_iam_service_account.k8s-service-account-node-group
  ]
}


