resource "aws_iam_instance_profile" "chef_infra_server" {
  name = "chef-infra-server"
  role = aws_iam_role.chef_infra_server.name
}

resource "aws_iam_role" "chef_infra_server" {
  name = "chef-infra-server"

  assume_role_policy = data.aws_iam_policy_document.assume_ec2_policy.json
}

data "aws_iam_policy_document" "assume_ec2_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "chef_infra_server-ssm_instance" {
  role       = aws_iam_role.chef_infra_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "chef_infra_server-cloud_watch_agent" {
  role       = aws_iam_role.chef_infra_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "chef_infra_server-chef_bucket_access" {
  role       = aws_iam_role.chef_infra_server.name
  policy_arn = aws_iam_policy.chef_bucket_access.arn
}

resource "aws_iam_policy" "chef_bucket_access" {
  name        = "chef_bucket_access"
  description = "Provides access to S3 bucket with Chef cookbooks"

  policy = data.aws_iam_policy_document.chef_bucket_access.json
}

data "aws_iam_policy_document" "chef_bucket_access" {
  statement {
    actions = ["s3:GetObject"]
    effect  = "Allow"
    resources = [
      "${aws_s3_bucket.chef_repo_archives.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "chef_infra_server-ssm_s3_bucket_access" {
  role       = aws_iam_role.chef_infra_server.name
  policy_arn = aws_iam_policy.ssm_s3_bucket_access.arn
}

# This is needed when using VPC Endpoints to access S3
# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview
resource "aws_iam_policy" "ssm_s3_bucket_access" {
  name        = "ssm_bucket_access"
  description = "Provides access to SSM S3 buckets in VPC Endpoint environments"

  policy = data.aws_iam_policy_document.ssm_s3_bucket_access.json
}

# https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent-minimum-s3-permissions.html
data "aws_iam_policy_document" "ssm_s3_bucket_access" {
  statement {
    sid     = replace(title(data.aws_region.current.name), "-", "")
    actions = ["s3:GetObject"]
    effect  = "Allow"
    resources = [
      "arn:aws:s3:::aws-ssm-${data.aws_region.current.name}/*",
      "arn:aws:s3:::aws-windows-downloads-${data.aws_region.current.name}/*",
      "arn:aws:s3:::amazon-ssm-${data.aws_region.current.name}/*",
      "arn:aws:s3:::amazon-ssm-packages-${data.aws_region.current.name}/*",
      "arn:aws:s3:::${data.aws_region.current.name}-birdwatcher-prod/*",
      "arn:aws:s3:::aws-ssm-document-attachments-${data.aws_region.current.name}/*",
      "arn:aws:s3:::patch-baseline-snapshot-${data.aws_region.current.name}/*",
    ]
  }
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
