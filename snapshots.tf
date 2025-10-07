resource "yandex_compute_snapshot_schedule" "daily_7d" {
  name = "daily-7d"
  schedule_policy { expression = "0 0 * * *" } # каждый день 00:00
  retention_period = "168h"                    # 7 дней

  snapshot_spec {
    description = "Daily snapshot"
    labels      = { env = "diploma" }
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.web_a.boot_disk[0].disk_id,
    yandex_compute_instance.web_b.boot_disk[0].disk_id,
    yandex_compute_instance.es_a.boot_disk[0].disk_id
  ]
}
