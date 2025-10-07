output "alb_external_ip" {
  description = "Публичный IP ALB (listener :80)"
  value       = try(yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, null)
}
