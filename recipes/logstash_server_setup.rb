
include_recipe "nginx_ssl_setup" if node['roles'].include?('https')
include_recipe "nginx"

include_recipe "TheCheftacularCookbook::sensu_gems"

template "/etc/nginx/sites-available/default" do
  source (node['roles'].include?('https') ? 'https_general_sites_available.erb' : 'general_sites_available.erb')
  owner  'root'
  group  node['root_group']
  mode   '0644'
  variables(
    name:       "logs.#{ data_bag_item('production', 'config').to_hash['production']['tld'] }",
    base_name:  'logs',
    log_dir:    node['nginx']['log_dir'],
    target_url: 'http://localhost:3000'
  )
  if ::File.exists?("#{node['nginx']['dir']}/sites-enabled/default")
    notifies :reload, 'service[nginx]'
  end
end

execute "ln -sf #{ node['nginx']['dir']}/sites-available/default #{ node['nginx']['dir']}/sites-enabled/default"

htpasswd "/etc/nginx/.htpassword" do
  user     'logstash'
  password Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["logstash_pass"]
end

service "nginx" do
  action :restart
end

include_recipe "logstash::server"
include_recipe "logstash::agent"
