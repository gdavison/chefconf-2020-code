# chef_automate Cookbook

This cookbook installs [Chef Automate](https://automate.chef.io).

## Requirements

### Platforms

* CentOS/RHEL 7, 8

### Chef Infra

* Chef Infra 15+

## Recipes

### default

The `default` recipe installs Chef Automate.

|Attribute|Description|Default|
|---------|-----------|-------|
|`node['chef_automate']['version']`|The version of Chef Automate to install, or `latest` for the latest version.|`latest`|
|`node['chef_automate']['channel']`|Channel to install the products from. It can be `stable`, `current` or `unstable`.|`current`|
|`node['chef_automate']['accept_license']`|Accept the Chef Automate license.|`false`|
|`node['chef_automate']['fqdn']`|FQDN of the Chef Automate instance.|`automate.example.com`|
