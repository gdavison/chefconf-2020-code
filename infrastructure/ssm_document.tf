resource "aws_ssm_document" "inspec_runner" {
  name          = "RunInspec"
  document_type = "Command"

  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<-EOT
    ---
    schemaVersion: "2.2"
    description: "Run one or more InSpec profiles on a set of managed instances."
    parameters:
      Profiles:
        type: "String"
        description: "InSpec profiles to run"
    mainSteps:
    - action: "aws:runShellScript"
      name: "runInSpec"
      inputs:
        runCommand:
        - "#!/usr/bin/env bash"
        # InSpec fails without HOME set
        - "export HOME=/root"
        # Accept the license
        - "export CHEF_LICENSE=accept-no-persist"
        # unset pipefail as inspec exits with error code if any tests fail
        - "set +eo pipefail"
        - "AUTOMATE_TOKEN=$(aws ssm get-parameter --name \"chef-automate-token\" --region ca-central-1 --with-decryption | jq  '.Parameter.Value' --raw-output)"
        - "inspec compliance login https://automate.chef-conf.encephalograham.ca --user admin --insecure --token \"$AUTOMATE_TOKEN\""
        - "inspec exec {{ Profiles }} --config /etc/chef/inspec.json"
        - "EXITCODE=$?"
        # InSpec exit codes are documented at https://www.inspec.io/docs/reference/cli/#exec
        - "case $EXITCODE in"
        - "    0       ) ;;"
        - "    10[0|1] ) exit 0 ;;"
        - "    *       ) ;;"
        - "esac"
        - "exit $EXITCODE"
    EOT
}
