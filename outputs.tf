output "component_arn" {
  description = "ARN of the EC2 Image Builder Component"
  value       = aws_cloudformation_stack.this.outputs["ComponentArn"]
}
