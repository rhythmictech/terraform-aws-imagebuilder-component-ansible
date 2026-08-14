# Tests for the repo_parts URL parsing in main.tf.
#
# The component document renders "ssh-keyscan -p <port> <host>" from the
# parsed URL whenever an SSH key is configured, so these tests assert on
# the rendered document to verify the parsing. Run with `terraform test`.

mock_provider "aws" {}

variables {
  name                = "test-component"
  component_version   = "1.0.0"
  ssh_key_secret_name = "test-ssh-key"
}

run "scp_style_azure_devops" {
  command = plan

  variables {
    playbook_repo = "username@vs-ssh.visualstudio.com:v3/org/project/reponame"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 vs-ssh.visualstudio.com")
    error_message = "expected host vs-ssh.visualstudio.com with default port 22"
  }
}

run "scp_style_github" {
  command = plan

  variables {
    playbook_repo = "git@github.com:rhythmictech/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected host github.com with default port 22"
  }
}

run "scp_style_with_branch" {
  command = plan

  variables {
    playbook_repo = "git@github.com:rhythmictech/ansible-playbooks.git -b mybranch"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected branch suffix to be ignored during parsing"
  }
}

run "ssh_url_with_port" {
  command = plan

  variables {
    playbook_repo = "ssh://git@github.com:2222/rhythmictech/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 2222 github.com")
    error_message = "expected explicit port 2222 from ssh:// URL"
  }
}

run "ssh_url_without_port" {
  command = plan

  variables {
    playbook_repo = "ssh://git@github.com/rhythmictech/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected default port 22 for ssh:// URL without port"
  }
}

run "ssh_url_with_branch" {
  command = plan

  variables {
    playbook_repo = "ssh://git@github.com/rhythmictech/ansible-playbooks.git -b feature"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected branch suffix to be ignored during parsing"
  }
}

run "https_url" {
  command = plan

  variables {
    playbook_repo = "https://github.com/rhythmictech/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected host github.com from https:// URL"
  }
}

run "https_url_without_git_suffix" {
  command = plan

  variables {
    playbook_repo = "https://github.example.com/org/ansible-playbooks"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.example.com")
    error_message = "expected host github.example.com from https:// URL without .git suffix"
  }
}

run "https_url_gitlab_subgroup" {
  command = plan

  variables {
    playbook_repo = "https://gitlab.com/group/subgroup/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 gitlab.com")
    error_message = "expected host gitlab.com from subgroup URL"
  }
}

run "https_url_azure_devops" {
  command = plan

  variables {
    playbook_repo = "https://dev.azure.com/myorg/myproject/_git/ansible-playbooks"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 dev.azure.com")
    error_message = "expected host dev.azure.com from Azure DevOps https URL"
  }
}

run "https_url_with_credentials" {
  command = plan

  variables {
    playbook_repo = "https://x-token-auth:abc123@bitbucket.example.com/scm/proj/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 bitbucket.example.com")
    error_message = "expected host bitbucket.example.com from URL with embedded credentials"
  }
}

run "ssh_url_gitlab_subgroup_with_port" {
  command = plan

  variables {
    playbook_repo = "ssh://git@gitlab.example.com:2222/group/subgroup/ansible-playbooks.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 2222 gitlab.example.com")
    error_message = "expected host gitlab.example.com with port 2222 from subgroup ssh URL"
  }
}

run "scp_style_azure_devops_ssh" {
  command = plan

  variables {
    playbook_repo = "git@ssh.dev.azure.com:v3/myorg/myproject/ansible-playbooks"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 ssh.dev.azure.com")
    error_message = "expected host ssh.dev.azure.com from Azure DevOps SCP-style URL"
  }
}

run "scp_style_dotted_repo_name" {
  command = plan

  variables {
    playbook_repo = "git@gitlab.example.com:group/sub.group/repo.name.git"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 gitlab.example.com")
    error_message = "expected dots in path segments to be accepted"
  }
}

run "long_branch_flag" {
  command = plan

  variables {
    playbook_repo = "git@github.com:rhythmictech/ansible-playbooks.git --branch feature/some-branch"
  }

  assert {
    condition     = strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan -p 22 github.com")
    error_message = "expected --branch suffix (with slashed branch name) to be ignored during parsing"
  }
}

# A repo URL that matches neither regex must not fail the plan when no
# SSH key is configured (the keyscan lines are not rendered in that case).
run "unparseable_url_without_ssh_key" {
  command = plan

  variables {
    playbook_repo       = "not a url at all"
    ssh_key_secret_name = null
  }

  assert {
    condition     = !strcontains(aws_imagebuilder_component.this.data, "ssh-keyscan")
    error_message = "expected no keyscan lines when no SSH key is configured"
  }
}

# When an SSH key IS configured, an unparseable repo URL must fail the
# plan with a clear precondition error rather than a template error.
run "unparseable_url_with_ssh_key" {
  command = plan

  variables {
    playbook_repo = "not a url at all"
  }

  expect_failures = [
    aws_imagebuilder_component.this
  ]
}
