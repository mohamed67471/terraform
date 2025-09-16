
output "public_ip" {
  value = aws_instance.this_public.public_ip
}

output "alb_dns_name" {
  value = aws_lb.wordpress.dns_name
  description = "The DNS name of the load balancer"
}
# ALB DNS name (to access WordPress)
output "wordpress_alb_dns" {
  description = "The DNS name of the WordPress ALB"
  value       = aws_lb.wordpress.dns_name
}

# WordPress private EC2 instance ID
output "wordpress_instance_id" {
  description = "The ID of the private WordPress EC2 instance"
  value       = aws_instance.this_private.id
}

# RDS endpoint (to connect WordPress to the DB)
output "wordpress_db_endpoint" {
  description = "The endpoint of the WordPress RDS database"
  value       = aws_db_instance.wordpress_db.endpoint
}

# RDS instance ID
output "wordpress_db_instance_id" {
  description = "The ID of the WordPress RDS instance"
  value       = aws_db_instance.wordpress_db.id
}