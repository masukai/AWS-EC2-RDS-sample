output "alb_listener_arn" {
  value = aws_lb_listener.main.arn
}

output "alb_main_arn" {
  value = aws_lb.main.arn
}
