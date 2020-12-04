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
            - export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
            # Get ssh key
            %{~ if ssh_key_name != null ~}
            # Install jq
            - sudo yum install -y jq
            - mkdir -p ~/.ssh
            - ssh-keyscan -p ${repo_port} ${repo_host} >> ~/.ssh/known_hosts
            - >
              aws --region
              $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
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
            %{~ if ssh_key_name != null ~}
            - ssh-keyscan -p ${repo_port} ${repo_host} >> ~/.ssh/known_hosts
            - eval "$(ssh-agent -s)"
            - ssh-add ~/.ssh/git_rsa
            %{~ endif ~}
            # Install playbook dependencies
            - ansible-galaxy install -f -r requirements.yml || true
            # Wait for cloud-init
            - while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
            # Run playbook
            - ansible-playbook ${playbook_file}
