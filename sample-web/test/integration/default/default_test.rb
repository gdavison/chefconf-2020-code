describe port(80), :skip do
  it { should be_listening }
end

describe service('nginx') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/var/www/nginx-default/index.html') do
  it { should exist }
  it { should be_file }
  its('mode') { should cmp '0644' }
end