# InSpec test for recipe chef_automate::default

describe toml(command: 'chef-automate config show') do
  its(%w(global v1 fqdn)) { should eq 'automate.example.com' }
end

describe service('chef-automate') do
  it { should be_enabled }
  it { should be_running }
end
