output "alb_dns_name" {
  description = "Adresse publique de l'application"
  value       = aws_lb.web.dns_name
}

output "target_group_arn" {
  description = "Target group des instances web"
  value       = aws_lb_target_group.web.arn
}

output "asg_name" {
  description = "Groupe d'auto-scaling"
  value       = aws_autoscaling_group.web.name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
