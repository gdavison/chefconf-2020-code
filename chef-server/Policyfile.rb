# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'chef-server'

# Where to find external cookbooks:
default_source :supermarket

run_list 'managed_chef_server::default', 'managed_chef_server::managed_organization'

default['mcs']['org']['name'] = 'test_org'

default['chef-server']['accept_license'] = true
