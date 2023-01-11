data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

output "component_arn" {
  description = "ARN of the EC2 Image Builder Component"
  value       = aws_imagebuilder_component.this.arn
}

output "latest_minor_version_arn" {
  description = "ARN of the EC2 Image Builder Component"
  value       = "arn:aws:imagebuilder:${local.region}:${local.account_id}:component/${lower(var.name)}/${local.latest_component_minor_version}"
}
