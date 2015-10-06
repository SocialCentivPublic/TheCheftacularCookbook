#Include recipes that should be run on EVERY system here

::Chef::Recipe.send(:include, TheCheftacularCookbook::Helper)

node.set['rvm']['default_ruby']              = "ruby-#{ node['desired_ruby'] }"
node.set['addresses'][node.chef_environment] = data_bag_item(node.chef_environment, 'addresses')['addresses']

include_recipe "TheCheftacularCookbook::setup_iptables"

include_recipe "rvm::user"
include_recipe "rvm::gem_package"

template "/etc/profile.d/rvm.sh" do
  source "rvm.sh.erb"
  owner "root"
  group "root"
  mode "755"
end

#Include set_code_defaults RIGHT BEFORE the execution of application specific code
#include_recipe "TheCheftacularCookbook::set_code_defaults" #set some variables via app_names that all app types use

include_recipe "TheCheftacularCookbook::mount_data_disk"
include_recipe "TheCheftacularCookbook::mount_swap"
include_recipe "apt"

package "ntp"

include_recipe "sudo"

sudo node['cheftacular']['deploy_user'] do
  user node['cheftacular']['deploy_user']
end

include_recipe "TheCheftacularCookbook::deploy_ssh_setup"
include_recipe "TheCheftacularCookbook::attribute_toggles"
include_recipe "rackspacecloud" if node['cloud'] == 'rackspace'
