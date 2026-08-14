name: ${name}-document
%{ if description != null ~}
description: ${description}
%{ endif ~}
schemaVersion: 1.0
phases:
  - name: build
    steps:
      - name: get-playbook
        action: ExecuteBash
        inputs:
          commands:
            - set -ex
            - sudo yum install -y git
            # Get ssh key
            %{~ if ssh_key_name != null && repo_host != null ~}
            # Install jq
            - sudo yum install -y jq
            - mkdir -p ~/.ssh
            - ssh-keyscan -p ${repo_port} ${repo_host} >> ~/.ssh/known_hosts
            # Resolve region from instance metadata (IMDSv2 token with IMDSv1 fallback)
            - |
              IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
              if [ -n "$IMDS_TOKEN" ]; then
                IMDS_AZ=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
              else
                IMDS_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              fi
              IMDS_REGION=$(echo "$IMDS_AZ" | sed 's/\(.*\)[a-z]/\1/')
            - >
              aws --region "$IMDS_REGION"
              --output json
              secretsmanager get-secret-value
              --secret-id ${ ssh_key_name }
              | jq -r .SecretString
              > ~/.ssh/git_rsa
            - chmod 0600 ~/.ssh/git_rsa
            - eval "$(ssh-agent -s)"
            - ssh-add ~/.ssh/git_rsa
            %{~ endif ~}
            - rm -rf ansible-repo
            - git clone --depth 1 ${playbook_repo} ansible-repo
      - name: run-playbook
        action: ExecuteBash
        inputs:
          commands:
            - set -ex
            - cd ansible-repo
            %{~ if playbook_dir != null ~}
            - cd ${playbook_dir}
            %{~ endif ~}
            %{~ if ssh_key_name != null && repo_host != null ~}
            - ssh-keyscan -p ${repo_port} ${repo_host} >> ~/.ssh/known_hosts
            - eval "$(ssh-agent -s)"
            - ssh-add ~/.ssh/git_rsa
            %{~ endif ~}
            %{~ if runner == "uv" ~}
            # Install uv into an isolated, unmanaged location and remove it on exit
            - UV_INSTALL_DIR="$(mktemp -d)"
            - trap 'rm -rf "$UV_INSTALL_DIR"' EXIT
            - curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="$UV_INSTALL_DIR" sh
            - export PATH="$UV_INSTALL_DIR:$PATH"
            # Set up the ansible environment via uv
            - uv sync
            %{~ else ~}
            - export PYENV_ROOT="${ansible_pyenv_path}"
            - export PATH="$PYENV_ROOT/bin:$PATH"
            - eval "$(pyenv init -)"
            - pyenv activate ansible
            %{~ endif ~}
            # Install playbook dependencies
            %{~ if runner == "uv" ~}
            - uv run ansible-galaxy role install -f -r requirements.yml || true
            - uv run ansible-galaxy collection install -f -r requirements.yml || true
            %{~ else ~}
            - ansible-galaxy role install -f -r requirements.yml || true
            - ansible-galaxy collection install -f -r requirements.yml || true
            %{~ endif ~}
            # Wait for cloud-init
            - while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
            # Work around for missing environment
            - export HOME=/root
            # Run playbook
            %{~ if runner == "uv" ~}
            - uv run ansible-playbook ${playbook_file}
            - rm -rf "$UV_INSTALL_DIR"
            %{~ else ~}
            - ansible-playbook ${playbook_file}
            %{~ endif ~}
      - name: cleanup-playbook 
        action: ExecuteBash
        inputs:
          commands:
            - rm -rf ansible-repo ~/.ansible
            - rm -f ~/.ssh/git_rsa ~/.ssh/known_hosts