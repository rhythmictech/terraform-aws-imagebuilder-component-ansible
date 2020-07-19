# terraform-aws-imagebuiluder-component-ansible

[![tflint](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /workflows/tflint/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /actions?query=workflow%3Atflint+event%3Apush+branch%3Amain)
[![tfsec](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /workflows/tfsec/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /actions?query=workflow%3Atfsec+event%3Apush+branch%3Amain)
[![yamllint](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /workflows/yamllint/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /actions?query=workflow%3Ayamllint+event%3Apush+branch%3Amain)
[![misspell](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /workflows/misspell/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /actions?query=workflow%3Amisspell+event%3Apush+branch%3Amain)
[![pre-commit-check](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /workflows/pre-commit-check/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-imagebuiluder-component-ansible /actions?query=workflow%3Apre-commit-check+event%3Apush+branch%3Amain)
<a href="https://twitter.com/intent/follow?screen_name=RhythmicTech"><img src="https://img.shields.io/twitter/follow/RhythmicTech?style=social&logo=twitter" alt="follow on Twitter"></a>


Terraform module that creates EC2 Image Builder components with CloudFormation

## Example
```hcl
module "test_component" {
  source  = "rhythmictech/imagebuilder-component-ansible/aws"
  version = "~> 0.2.0"

  component_version = "1.0.0"
  description       = "Testing component"
  name              = "testing-component"
  playbook_dir      = "packer-generic-images/base"
  playbook_repo     = "https://github.com/rhythmictech/packer-generic-images.git"
  tags              = local.tags
}
```

## About
This module bridges the gap allowing Terraform to create EC2 Image Builder components (especially with Ansible) until native support is added to Terraform

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.20 |
| aws | ~> 2.44 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.44 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| component\_version | Version of the component | `string` | n/a | yes |
| name | name to use for component | `string` | n/a | yes |
| playbook\_repo | git url for repo where ansible code lives | `string` | n/a | yes |
| change\_description | description of changes since last version | `string` | `null` | no |
| cloudformation\_timeout | How long to wait (in minutes) for CFN to apply before giving up | `number` | `10` | no |
| data\_uri | Use this to override the component document with one at a particualar URL endpoint | `string` | `null` | no |
| description | description of component | `string` | `null` | no |
| kms\_key\_id | KMS key to use for encryption | `string` | `null` | no |
| platform | platform of component (Linux or Windows) | `string` | `"Linux"` | no |
| playbook\_dir | directory where playbook and requirements are found (if not root of repo) | `string` | `null` | no |
| playbook\_file | path to playbook file, relative to `playbook_dir` | `string` | `"provision.yml"` | no |
| ssh\_key\_secret\_arn | ARN of a secretsmanager secret containing an SSH key (use arn OR name, not both) | `string` | `null` | no |
| ssh\_key\_secret\_name | Name of a secretsmanager secret containing an SSH key (use arn OR name, not both) | `string` | `null` | no |
| tags | map of tags to use for CFN stack and component | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| component\_arn | ARN of the EC2 Image Builder Component |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## The Giants underneath this module
- pre-commit.com/
- terraform.io/
- github.com/tfutils/tfenv
- github.com/segmentio/terraform-docs
