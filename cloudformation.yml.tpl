Type: AWS::ImageBuilder::Component
Properties:
  Name: ${name}
  Version: ${version}
  %{~ if change_description != null ~}
  ChangeDescription: ${change_description}
  %{~ endif ~}
  %{~ if description != null ~}
  Description: ${description}
  %{~ endif ~}
  %{~ if kms_key_id != null ~}
  KmsKeyId: ${kms_key_id}
  %{~ endif ~}
  Platform: ${platform}
  Tags:
    ${ indent(4, chomp(yamlencode(tags))) }
  %{~ if uri != null ~}
  Uri: ${uri}
  %{~ endif ~}
  %{~ if data != null ~}
  Data: |
    ${indent(4, data)}
  %{~ endif ~}
