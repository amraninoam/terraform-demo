output "alb_dns_name" {
  description = "Paste this in a browser once the ASG is healthy."
  value       = aws_lb.alb.dns_name
}
