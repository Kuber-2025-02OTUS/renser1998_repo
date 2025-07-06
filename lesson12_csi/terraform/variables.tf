variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
}

variable "cloud_id" {
  description = "Yandex Cloud Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in node group"
  type        = number
  default     = 2
}


