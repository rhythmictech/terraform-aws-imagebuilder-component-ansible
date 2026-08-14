locals {
  has_ssh_key                    = var.ssh_key_secret_arn != null || var.ssh_key_secret_name != null
  latest_component_minor_version = "${split(".", var.component_version)[0]}.${split(".", var.component_version)[1]}.x"

  data = templatefile("${path.module}/component.yml.tpl", {
    ansible_pyenv_path = var.ansible_pyenv_path
    description        = var.description
    name               = var.name
    playbook_dir       = var.playbook_dir
    playbook_file      = var.playbook_file
    playbook_repo      = var.playbook_repo
    python_version     = var.python_version
    runner             = var.runner
    repo_host          = try(local.repo_parts.host, null)
    repo_port          = try(coalesce(local.repo_parts.port, 22), 22)
    ssh_key_name       = try(data.aws_secretsmanager_secret.ssh_key[0].name, null)
  })

  # Strip an optional trailing "-b <branch>" / "--branch <branch>" clone
  # argument before parsing the URL itself.
  repo_url = trimspace(replace(trimspace(var.playbook_repo), "/\\s+(-b|--branch)[ =]+\\S+$/", ""))

  # Extract host/port for ssh-keyscan. Only the host and port matter here,
  # so the path is intentionally unconstrained (any depth, ".git" optional)
  # to support GitHub, GitLab subgroups, GitHub Enterprise, Bitbucket,
  # Azure DevOps (dev.azure.com/org/project/_git/repo), etc.
  # Matches protocol-style URLs (scheme://[user[:token]@]host[:port][/path])
  # first, then falls back to SCP-style URLs ([user@]host:path, e.g. Azure
  # DevOps username@vs-ssh.visualstudio.com:v3/org/project/repo), which
  # have no port syntax.
  repo_parts = try(
    regex(
      "^(?P<protocol>[A-Za-z][A-Za-z0-9+.-]*)://(?:(?P<user>[^@/\\s]+)@)?(?P<host>[^:/@\\s]+)(?::(?P<port>\\d+))?(?:/(?P<path>\\S*))?$",
      local.repo_url
    ),
    merge(
      { protocol = "ssh", port = null },
      regex(
        "^(?:(?P<user>[^@/\\s]+)@)?(?P<host>[^:/@\\s]+):(?P<path>\\S+)$",
        local.repo_url
      )
    ),
    null
  )
}

data "aws_secretsmanager_secret" "ssh_key" {
  count = local.has_ssh_key ? 1 : 0

  arn  = var.ssh_key_secret_arn
  name = var.ssh_key_secret_name
}

resource "aws_imagebuilder_component" "this" {
  name    = var.name
  version = var.component_version

  change_description    = var.change_description
  data                  = var.data_uri == null ? local.data : null
  description           = var.description
  kms_key_id            = var.kms_key_id
  platform              = var.platform
  supported_os_versions = var.supported_os_versions
  uri                   = var.data_uri

  tags = merge(
    var.tags,
    { Name : "${var.name}-stack" }
  )

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.data_uri != null || !local.has_ssh_key || local.repo_parts != null
      error_message = "playbook_repo could not be parsed for its host, which is required for ssh-keyscan when an SSH key is configured. Supported forms: scheme://[user@]host[:port]/path (e.g. https://, ssh://, git://) or SCP-style [user@]host:path, optionally followed by \"-b <branch>\"."
    }
  }
}
