#this is a file for one off tasks that need to be run after the db and rails stack have been installed / updated

include_recipe "TheCheftacularCookbook"

node.force_override['environment_name'] = 'test' #just in case this is a "test" server in a different environment?

execute "setup_chef-client_daemon" do
  command "/opt/chef/embedded/bin/ruby /usr/bin/chef-client -d -s #{ node['TheCheftacularCookbook']['sensu_build']['chef_daemon_delay'] }"
  user    "root"
  not_if  "ps aux | grep '/opt/chef/embedded/bin/ruby /usr/bin/chef-client -d -s #{ node['TheCheftacularCookbook']['sensu_build']['chef_daemon_delay'] }' | grep -v grep"
end
