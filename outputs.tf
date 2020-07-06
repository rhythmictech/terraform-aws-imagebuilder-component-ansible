data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

output "component_arn" {
  description = "ARN of the EC2 Image Builder Component"
  value       = "arn:aws:imagebuilder:${local.region}:${local.account_id}:component/${lower(var.name)}/${var.component_version}/1"

  depends_on = [
    aws_cloudformation_stack.this
  ]
}
