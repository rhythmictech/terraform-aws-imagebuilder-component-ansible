variable "change_description" {
  default     = null
  description = "description of changes since last version"
  type        = string
}

variable "cloudformation_timeout" {
  default     = 10
  description = "How long to wait (in minutes) for CFN to apply before giving up"
  type        = number
}

variable "component_version" {
  description = "Version of the component"
  type        = string
}

variable "data_uri" {
  default     = null
  description = "Use this to override the component document with one at a particualar URL endpoint"
  type        = string
}

variable "description" {
  default     = null
  description = "description of component"
  type        = string
}

variable "kms_key_id" {
  default     = null
  description = "KMS key to use for encryption"
  type        = string
}

variable "name" {
  description = "name to use for component"
  type        = string
}

# TODO: add validation
variable "platform" {
  default     = "Linux"
  description = "platform of component (Linux or Windows)"
  type        = string
}

variable "playbook_dir" {
  default     = null
  description = "directory where playbook and requirements are found (if not root of repo)"
  type        = string
}

variable "playbook_file" {
  default     = "provision.yml"
  description = "path to playbook file, relative to `playbook_dir`"
  type        = string
}

variable "playbook_repo" {
  description = <<EOD
git url for repo where ansible code lives with provisioning playbook and requirements file
can append with `-b BRANCH_NAME` to clone a specific branch
EOD
  type        = string
}

variable "ssh_key_secret_arn" {
  default     = null
  description = "ARN of a secretsmanager secret containing an SSH key (use arn OR name, not both)"
  type        = string
}

variable "ssh_key_secret_name" {
  default     = null
  description = "Name of a secretsmanager secret containing an SSH key (use arn OR name, not both)"
  type        = string
}

variable "tags" {
  default     = {}
  description = "map of tags to use for CFN stack and component"
  type        = map(string)
}
