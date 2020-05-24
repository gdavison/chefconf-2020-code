# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'sample-web'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'sample-web::default', 'chef-client::delete_validation', 'inspec_cron::inspec-json'

# Specify a custom source for a single cookbook:
cookbook 'sample-web', path: '.'

cookbook 'nginx',       '~> 10.0.2'
cookbook 'chef-client', '~> 11.5.0'
cookbook 'inspec_cron', '~> 0.5.0'
