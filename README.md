# chefconf-2020-code

This is the assembled code used in my [ChefConf Online 2020](https://www.chefconf.io) talk.

Using AWS infrastructure, it creates

* A [Chef Automate](https://automate.chef.io) server
* A [Chef Infra Server](https://www.chef.sh/about/chef-server/)
* An autoscaling group with instances configured with a simple Nginx installation

All instances are created in a single VPC.

## Prerequisites

You will need to have or create an [AWS account](https://aws.amazon.com). Some of the resources created are **not** eligible for the [AWS Free Tier](https://aws.amazon.com/free/).

Install [Terraform](https://www.terraform.io/downloads.html). Terraform can also be installed using [various package managers](https://learn.hashicorp.com/terraform/getting-started/install.html).

Install [Chef Workstation](https://docs.chef.io/workstation/).

Optionally, install [jq](https://stedolan.github.io/jq/download/). jq is a utility for manipulating JSON and can be used in a configuration step below.

## Subdirectories

### chef-server

This directory contains a Policyfile that deploys and configures Chef Infra Server.

It makes use of the [`managed_chef_server` cookbook](https://supermarket.chef.io/cookbooks/managed_chef_server).

### sample-web

This directory contains a cookbook that configures a simple static website served by Nginx.

The Policyfile also uses the [`chef-client` cookbook](https://supermarket.chef.io/cookbooks/chef-client) to clean up Chef Infra Client validation and the [`inspec_cron` cookbook](https://supermarket.chef.io/cookbooks/inspec_cron) to configure the InSpec configuration file.

### infrastructure

This directory contains the Terraform configuration that deploys the infrastructure for the demonstration.

Individual hosts can be connected to using [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). This means that no SSH keys are needed.

**Note:** This configuration needs to be refactored to accommodate various manual steps. It was developed step-by-step as one configuration, but this won't work all at once. [Resource targeting](https://www.terraform.io/docs/commands/plan.html#resource-targeting) can be used to work around this.

## Deployment

### Terraform Configuration

#### Authenticating with AWS

Before deploying the infrastructure to AWS, you will need to have credentials for an AWS account. The Terraform AWS provider can be authenticated with AWS in [several ways](https://www.terraform.io/docs/providers/aws/index.html). Which method you use will be guided by what credentials you have.

If you have configured [access for the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html), you can supply the environment variable `AWS_PROFILE` with the name of the profile to use. The default profile is named `default`. You may need to set the AWS region using the `AWS_DEFAULT_REGION` environment variable or editing the provider block in `infrastructure/main.tf`.

If you haven't configured the AWS CLI, but have an access key and secret access key, these can be specified using the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, respectively.

#### Your Public IP Address

By default, the security groups for the instances this sample creates are only accessible from a single IP address, assigned using the Terraform input variable `my_ip`. You can configure this manually in the `infrastructure/terraform.tfvars` file, or run the following command, which will create a JSON variable definition file. This requires the jq utility.

```shell
dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed s/\"//g | jq '. | {my_ip: .}' --raw-input > infrastructure/terraform.tfvars.json
```

This command retrieves your public IPv4 address using Google's DNS servers, trims the output, then outputs the JSON file.

#### Domain Name

The infrastructure configures [public and internal Route 53 DNS zones](https://en.wikipedia.org/wiki/Split-horizon_DNS) for Chef Automate and the Chef Infra Server. The Terraform configuration takes an input variable, `parent_domain_name`, which can be configured in the `infrastructure/terraform.tfvars` file. The infrastructure created will use the subdomain `chef-conf.<parent_domain_name>`.

**Note:** It may be possible to configure the infrastructure without using Route 53, and overriding name resolution by, e.g. modifying the [`/etc/hosts` file on your workstation](https://provisiondata.com/kb/using-etchosts-file-custom-domains-development/). The host names will still need to be set on Chef Automate and possibly Chef Infra Server.

#### Chef Infra Server Admin User

The Chef Infra Server is configured with a default organization and admin user. You need to supply an email address for the Chef Infra Server user in the Terraform input variable `chef_server_admin_email` in the `infrastructure/terraform.tfvars` file.

### Create the S3 Bucket

The S3 bucket is used to store the chef-repo archive used to configure the Chef Infra Server.

It can be deployed running `terraform apply -target='aws_s3_bucket_public_access_block.example'` from the `infrastructure` directory.

You will use the name of the S3 bucket when uploading the Chef Infra Server repo.

### Deploy the Chef Automate Server

The remaining infrastructure depends on Chef Automate, so it must be deployed first.

It can be deployed by running `terraform apply -target='module.chef_automate'` from the `infrastructure` directory.

Once the instance is running, connect to the instance using the [AWS Systems Manager Session Manager console](https://console.aws.amazon.com/systems-manager/session-manager/sessions) so that you can configure the server.

Follow the [Chef Automate installation instructions](https://automate.chef.io/docs/install/):

1. Download the installer: `curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate`

1. Create a default configuration: `sudo ./chef-automate init-config`. This will create a `config.toml` file.

1. Set the domain name for your Chef Automate server in `config.toml`, at the value `fqdn`. This will be `automate.chef-conf.<parent_domain_name>`.

1. Deploy Chef Automate: `sudo ./chef-automate deploy config.toml`. This will take a few minutes.

1. Save the contents of the `automate-credentials.toml` file created by the deploy script. You will use these credentials to log on as an administrator in the next step.

1. Using a web browser, connect to your Chef Automate instance at `https://automate.chef-conf.<your domain>/`. This is configured with a self-signed certificate.

1. [Create an API token](https://automate.chef.io/docs/api-tokens/#creating-api-tokens) that will be used for data collection from Chef Infra Server.

1. Store the token value in [AWS Systems Manager Parameter Store](https://console.aws.amazon.com/systems-manager/parameters/) as a `SecureString` with the name `chef-automate-token`.

1. Install the compliance profiles needed by going to the Compliance tab and selecting Profiles. Search for and download the "DevSec Linux Security Baseline" and "DevSec Nginx Baseline" profiles.

### Upload the Chef Infra Archive to the S3 Bucket

Before the Chef Infra Server can be deployed, you will need to package the policy for the Chef Infra Server.

In the `chef-server` directory, run the following commands:

1. `chef install`: this will evaluate the `Policyfile.rb` and create the locked policy set in the file `Policyfile.lock.json`.

1. `chef export --archive`: this will create a zipped archive of a chef-repo that can be used by chef-client local mode.

1. Upload the chef-repo archive to the S3 bucket created above with the name `chef-server.tgz`. You can use the web console or the AWS CLI with the command `aws s3 cp <local-file-name> s3://<bucket-name>/chef-server.tgz`.

### Deploy Chef Infra Server

Next, the Chef Infra Server needs to be deployed.

It can be deployed by running `terraform apply -target='module.chef_infra_server'` from the `infrastructure` directory. The server hostname will be `https://server.chef-conf.<your domain>/`.

Once the instance is running, connect to the instance using the [AWS Systems Manager Session Manager console](https://console.aws.amazon.com/systems-manager/session-manager/sessions) so that you can configure the server.  The Chef Infra Server setup has created an Organization and an administrator user, named `test_org` and `chef_managed_user_test_org`, respectively.

First, configure Chef Infra Server data collection using the instructions at https://automate.chef.io/docs/data-collection/

1. Set the data collector token to the token created in Chef Automate by running the command `sudo chef-server-ctl set-secret data_collector token '<token-value>'`.

1. Restart Nginx and the API server by running the commands `sudo chef-server-ctl restart nginx` and `sudo chef-server-ctl restart opscode-erchef`.

1. Add the following settings to the Chef Infra Server configuration file, `/etc/opscode/chef-server.rb`:
```ruby
data_collector['root_url'] = 'https://<chef-automate-hostname>/data-collector/v0/'
data_collector['proxy']    = true
profiles['root_url']       = 'https://<chef-automate-hostname>'
```

1. Save the `test_org` validation key found at `/etc/opscode/managed/test_org/test_org-validator.pem` in AWS Systems Manager Parameter Store as a `SecureString` with the name `chef-infra-server-validator`. You can use the web console. This will be used by the test instances to register with the Chef Infra Server.

Next, configure Chef Infra tools on your workstation.

1. Copy the user key found at `/etc/opscode/managed/test_org/test_org-user.key` and save it on your workstation as `~/.chef/test_org-user.pem`.

1. On your workstation, run the command `knife configure`. When prompted for the Chef Infra Server URL, enter `https://<chef-infra-server-hostname>/organizations/test_org`. When prompted for the username, enter `test_org-user`.

1. The Chef Infra Server is configured to use a self-signed TLS certificate. To add the certificate to Chef Infra's trusted certificates, run the command `knife ssl fetch`.

### Build the Profile for the Sample Web Servers

Here, we compile the Policyfile and upload it to the Chef Infra Server so that it can be used to configure the sample web servers.


In the `sample-web` directory, run the following commands:

1. `chef install`: this will evaluate the `Policyfile.rb` and create the locked policy set in the file `Policyfile.lock.json`.

1. `chef push web-sample`: this will upload the policy `sample-web` to the policy group `web-sample` on the Chef Infra Server. Yes, the names are confusing.

The `sample-web` cookbook has integration tests that can be run using `kitchen test`. It is currently set up to use [Vagrant](https://www.vagrantup.com) and [VirtualBox](https://www.virtualbox.org).

### Deploy Everything Else

Finally, we can deploy the rest of the system, which will deploy an autoscaling group with the sample web servers. These will have InSpec automatically run against them by the [AWS Systems Manager State Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state.html).

Run the command `terraform apply` from the `infrastructure` directory. All remaining resources will be deployed.

The InSpec runs will be sent to Chef Automate, and can be viewed on the Compliance tab of your Chef Automate web interface.

**Note:** The first InSpec run currently does not complete because a required file is not present at the time of the first run.
