
include_recipe "TheCheftacularCookbook"

node.set['sensu']['use_embedded_ruby'] = true

include_recipe "sensu"

sensu_host = "localhost"

execute "chown sensu:root -R /etc/chef"

unless node['roles'].include?('sensu_server')

  include_recipe "TheCheftacularCookbook::sensu_gems"
  
  include_recipe "TheCheftacularCookbook::sensu_check_file_setup"

  #we do not want to setup clients if there is no sensu node to recieve them
  data_bag_item( 'production', 'addresses')['addresses'].each do |serv_hash|
    next unless serv_hash['name'] == 'sensu'

    sensu_host = serv_hash['address']

    node.set['sensu']['rabbitmq']['host']     = sensu_host
    node.set['sensu']['rabbitmq']['password'] = Chef::EncryptedDataBagItem.load( 'production', 'chef_passwords', node['secret'])["rabbitmq_sensu_pass"]

    node.set['sensu']['redis']['host']        = sensu_host

    node.set['sensu']['api']['host']          = sensu_host

    sensu_client node.name do
      address node.ipaddress
      subscriptions node.roles + ["all"] + [node.name]
    end

    execute "rm -rf /etc/sensu/conf.d/checks" do
      only_if  { ::Dir.exists?('/etc/sensu/conf.d/checks') }
    end

    include_recipe "sensu::client_service"

    break
  end
end
