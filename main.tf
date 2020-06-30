locals {
  has_ssh_key = var.ssh_key_secret_arn != null || var.ssh_key_secret_name != null

  data = templatefile("${path.module}/component.yml.tpl", {
    description   = var.description
    name          = var.name
    playbook_dir  = var.playbook_dir
    playbook_file = var.playbook_file
    playbook_repo = var.playbook_repo
    ssh_key_name  = try(data.aws_secretsmanager_secret.ssh_key[0].name, null)
  })

}

data "aws_secretsmanager_secret" "ssh_key" {
  count = local.has_ssh_key ? 1 : 0

  arn  = var.ssh_key_secret_arn
  name = var.ssh_key_secret_name
}

resource "aws_cloudformation_stack" "this" {
  name               = var.name
  on_failure         = "ROLLBACK"
  timeout_in_minutes = var.cloudformation_timeout

  tags = merge(
    var.tags,
    { Name : "${var.name}-stack" }
  )

  template_body = templatefile("${path.module}/cloudformation.yml.tpl", {
    change_description = var.change_description
    data               = local.data
    description        = var.description
    kms_key_id         = var.kms_key_id
    name               = var.name
    platform           = var.platform
    uri                = var.data_uri
    version            = var.component_version

    tags = merge(
      var.tags,
      { Name : var.name }
    )
  })
}
