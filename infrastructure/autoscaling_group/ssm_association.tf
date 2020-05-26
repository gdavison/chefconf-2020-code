resource "aws_ssm_association" "run_inspec" {
  name = var.inspec_runner_ssm_document_name

  document_version    = "$DEFAULT"
  compliance_severity = "UNSPECIFIED"

  schedule_expression = "cron(0 */30 * * * ? *)"
  parameters = {
    Profiles = "compliance://admin/linux-baseline compliance://admin/nginx-baseline"
  }
  targets {
    key = "tag:Name"
    values = [
      "Web Sample",
    ]
  }
}
