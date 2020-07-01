name: ${name}-document
%{ if description != null ~}
description: ${description}
%{ endif ~}
schemaVersion: 1.0
phases:
  - name: build
    steps:
      - name: ansible-install
        action: ExecuteBash
        inputs:
          commands:
            # Install Ansible dependencies
            - sudo yum install -y python python3 python-pip python3-pip git
            # Enable Ansible repository
            - sudo amazon-linux-extras enable ansible2
            # Install Ansible
            - sudo yum install -y ansible
      - name: get-playbook
        action: ExecuteBash
        inputs:
          commands:
            - set -ex
            # Get ssh key
            %{~ if ssh_key_name != null ~}
            # Install jq
            - sudo yum install -y jq
            - mkdir -p ~/.ssh
            - export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
            - aws --region $${AWS_REGION} secretsmanager get-secret-value --secret-id ${ ssh_key_name } | jq -r '.SecretString.private_key' > ~/.ssh/git_rsa
            - ssh-add ~/.ssh/git_rsa
            %{~ endif ~}
            - git clone --depth 1 ${playbook_repo}
      - name: run-playbook
        action: ExecuteBash
        inputs:
          commands:
            %{~ if playbook_dir != null ~}
            - cd ${playbook_dir}
            %{~ endif ~}
            # Install playbook dependencies
            - ansible-galaxy install -f -r requirements.yml || true
            # Wait for cloud-init
            - while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
            # Run playbook
            - ansible-playbook ${playbook_file}
      - name: cleanup
        action: ExecuteBash
        inputs:
          commands:
            - sudo yum remove -y ansible
            - sudo yum autoremove -y
            - sudo rm -rf packer-generic-images
            - sudo rm -rf ~/.ansible/roles /usr/share/ansible/roles /etc/ansible/roles
