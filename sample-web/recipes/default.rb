#
# Cookbook:: sample-web
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

nginx_install 'repo'

directory '/var/www/nginx-default' do
  recursive true
end

template File.join('/var/www/nginx-default', 'index.html') do
  source 'index.html.erb'
end
