
include_recipe "TheCheftacularCookbook"

node.set['sensu']['use_embedded_ruby'] = true

include_recipe "sensu"

node.set['sensu']['rabbitmq']['password'] = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["rabbitmq_sensu_pass"]

include_recipe "sensu::rabbitmq"

include_recipe "sensu::redis"

#TODO FIXME WHEN 0.4.1-1 IS ADDED
node.set['uchiwa']['version'] = '0.4.0-1'
node.set['uchiwa']['settings']['user']    = node['TheCheftacularCookbook']['sensu']['uchiwa_http_basic_username']
node.set['uchiwa']['settings']['pass']    = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["uchiwa_pass"]
node.set['uchiwa']['settings']['refresh'] = 10000
node.set['uchiwa']['api'] = [
  {
    'name'    => 'Sensu',
    'host'    => '127.0.0.1',
    'port'    => 4567,
    'path'    => '',
    'ssl'     => false,
    'timeout' => 6000
  }
]

include_recipe "uchiwa"
include_recipe "nginx_ssl_setup" if node['roles'].include?('https')
include_recipe "nginx"

include_recipe "TheCheftacularCookbook::sensu_gems"

template "/etc/nginx/sites-available/default" do
  source (node['roles'].include?('https') ? 'https_general_sites_available.erb' : 'general_sites_available.erb')
  owner  'root'
  group  node['root_group']
  mode   '0644'
  variables(
    name:       "sensu.#{ data_bag_item('production', 'config').to_hash['production']['tld'] }",
    base_name:  'sensu',
    log_dir:    node['nginx']['log_dir'],
    target_url: 'http://localhost:3000'
  )
  if ::File.exists?("#{node['nginx']['dir']}/sites-enabled/default")
    notifies :reload, 'service[nginx]'
  end
end

execute "ln -sf #{ node['nginx']['dir']}/sites-available/default #{ node['nginx']['dir']}/sites-enabled/default"

sensu_client node.name do
  address "localhost"
  subscriptions node.roles + ["all"] + [node.name]
end

data_bag_item('production','addresses')['addresses'].each do |serv_hash|
  next unless serv_hash['name'] == 'sensu' 

  node.set['sensu']['local_ip_address'] = serv_hash['address']
end

include_recipe "sensu::client_service"

include_recipe "TheCheftacularCookbook::sensu_check_file_setup"

include_recipe "TheCheftacularCookbook::sensu_server_handlers_setup"

include_recipe "TheCheftacularCookbook::sensu_server_checks_setup"

node['TheCheftacularCookbook']['sensu']['additional_sensu_server_checks'].each_value do |check_hash|
  include_recipe "#{ check_hash['cookbook'] }::#{ check_hash['filename_without_extension'] }"
end 

include_recipe "TheCheftacularCookbook::sensu_server_metrics_setup"

include_recipe "TheCheftacularCookbook::sensu_server_filters_setup"

include_recipe "TheCheftacularCookbook::sensu_server_cron_setup"

include_recipe "sensu::server_service"

include_recipe "sensu::api_service"
