
node.set['elkstack']['config']['cloud_monitoring']['enabled'] = false

include_recipe "TheCheftacularCookbook"

include_recipe "TheCheftacularCookbook::logstash_shared_pre_setup"

server_config_name_array = []
base_config_hash  = {}

node['TheCheftacularCookbook']['logstash']['server_configurations'].each_pair do |server_config_name, server_config_hash|
  base_config_hash[server_config_name] = {
    'name'      => server_config_name,
    'source'    => (server_config_hash.has_key?('source') ? server_config_hash['source'] : 'logstash/input_file.conf.erb'),
    'cookbook'  => (server_config_hash.has_key?('cookbook') ? server_config_hash['cookbook'] : 'TheCheftacularCookbook'),
    'variables' => node['elkstack']['shared_variables'].merge(server_config_hash['variables'])
  }

  server_config_name_array << server_config_name
end

node.set['elkstack']['config']['custom_logstash'] = base_config_hash
node.set['elkstack']['config']['custom_logstash']['name'] = server_config_name_array
node.set['kibana']['server_name'] = "logs.#{ data_bag_item('production', 'config').to_hash['production']['tld'] }"

include_recipe "java"
include_recipe "elkstack"

htpasswd "/etc/nginx/htpassword" do
  user     node['TheCheftacularCookbook']['logstash']['logstash_auth_user']
  password Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["logstash_pass"]
end

include_recipe "TheCheftacularCookbook::logstash_shared_post_setup"

cookbook_file node['nginx']['ssl_key'] do
  source   node['TheCheftacularCookbook']['nginx']['ssl']['ssl_key_file_name'].gsub('ENVIRONMENT', node.chef_environment)
  owner    'root'
  group    'root'
  mode     '0644'
  cookbook node['TheCheftacularCookbook']['nginx']['ssl']['cookbook_containing_ssl_certs']
  action  :create
end

cookbook_file node['nginx']['ssl_cert'] do
  source   node['TheCheftacularCookbook']['nginx']['ssl']['ssl_crt_file_name'].gsub('ENVIRONMENT', node.chef_environment)
  owner    'root'
  group    'root'
  mode     '0644'
  cookbook node['TheCheftacularCookbook']['nginx']['ssl']['cookbook_containing_ssl_certs']
  action  :create
end

service "nginx" do
  action :restart
end
