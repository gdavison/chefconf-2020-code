#!/usr/bin/env bash

# Create directories
/bin/mkdir -p /etc/chef
/bin/mkdir -p /var/lib/chef
/bin/mkdir -p /var/log/chef

# Get the Chef Infra validator from SSM Parameter Store
aws ssm get-parameter --name "chef-infra-server-validator" --region ca-central-1 --with-decryption \
    | jq '.Parameter.Value' --raw-output \
    | sed 's/\\n/\n/g' \
    > /etc/chef/test_org-validator.pem

# Get the Chef Automate token from SSM Parameter Store
AUTOMATE_TOKEN=$(aws ssm get-parameter --name "chef-automate-token" --region ca-central-1 --with-decryption \
    | jq  '.Parameter.Value' --raw-output)

# Configure the client.rb file
/bin/echo -e "chef_server_url  \"https://${chef_infra_server_url}/organizations/test_org\"" >> /etc/chef/client.rb
/bin/echo -e "validation_client_name \"test_org-validator\"" >> /etc/chef/client.rb
/bin/echo -e "validation_key \"/etc/chef/test_org-validator.pem\"" >> /etc/chef/client.rb
/bin/echo -e "policy_group \"web-sample\"" >> /etc/chef/client.rb
/bin/echo -e "policy_name \"sample-web\"" >> /etc/chef/client.rb
/bin/echo -e "ssl_verify_mode :verify_none" >> /etc/chef/client.rb

# Run Chef Infra Client
jq --null-input --arg url ${chef_automate_server_url} --arg token $AUTOMATE_TOKEN '{"inspec_cron": {"server_url": $url, "token": $token, "insecure": true}}' > attributes.json
chef-client --chef-license accept-silent --json-attributes attributes.json
