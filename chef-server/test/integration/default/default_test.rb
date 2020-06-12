describe port(80) do
  it { should be_listening }
end

describe port(443) do
  it { should be_listening }
end

managed_dir = Pathname.new('/etc/opscode/managed')

describe directory managed_dir do
  it { should exist }
end

organization_name = 'example_org'
organization_dir  = managed_dir.join(organization_name)

describe directory organization_dir do
  it { should exist }
end

organization_user_name      = "chef_managed_user_#{organization_name}"
organization_validator_file = "#{organization_name}-validator.pem"
user_key_file               = "#{organization_name}-user.key"

organization_validator_path = organization_dir.join(organization_validator_file)
user_key_path               = organization_dir.join(user_key_file)

# config.rb
[ organization_dir.join('config.rb'), organization_dir.join('config.json') ].each do |conf|
  describe file conf do
    it { should exist }
    its('mode') { should cmp '0400' }
    its('content') { should match %r{chef_server_url.*https://localhost/organizations/#{organization_name}} }
    its('content') { should match /validation_client_name.*#{organization_name}/ }
    its('content') { should match %r{validation_key.*#{organization_validator_path}} }
    its('content') { should match %r{client_key.*#{user_key_path}} }
    its('content') { should match /node_name.*#{organization_user_name}/ }
  end
end

describe file organization_validator_path do
  it { should exist }
end

describe file user_key_path do
  it { should exist }
end
