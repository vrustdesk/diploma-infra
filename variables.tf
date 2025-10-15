variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID (пример: b1gxxxxxxxxxxxxxxx)"
}
variable "folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID (пример: b1gxxxxxxxxxxxxxxx)"
}
variable "zone_a" {
  type        = string
  description = "Primary zone"
  default     = "ru-central1-a"
}
variable "zone_b" {
  type        = string
  description = "Secondary zone"
  default     = "ru-central1-b"
}
variable "ssh_pub_key" {
  type        = string
  description = "SSH public key"
}
variable "image_id" {
  type        = string
  description = "Ubuntu image ID"
}
variable "preemptible" {
  type        = bool
  description = "Use preemptible VMs"
  default     = true
}
variable "snapshot_retention_days" {
  type        = number
  description = "Retention for snapshots (days)"
  default     = 7
}
variable "yc_token" {
  type        = string
  description = "YC OAuth/IAM token"
  default     = null
  sensitive   = true
}
variable "sa_key_file" {
  type        = string
  description = "Path to service account key JSON (Linux путь на bastion)"
  default     = null
  sensitive   = true
}

# --- добавлено для VPC ---
variable "subnets" {
  type = map(object({
    zone = string
    cidr = list(string)
  }))
}

# --- добавлено для web for_each ---
variable "web_nodes" {
  type = map(object({
    zone   = string
    subnet = string
  }))
}
