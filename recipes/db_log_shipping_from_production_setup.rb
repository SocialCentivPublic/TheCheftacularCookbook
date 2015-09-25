
node.set['receive_backups']               = true
node.set['main_backup_location']          = '/mnt/postgresbackups/backups'
node.set['filesystem_pg_backup_location'] = "#{ node['main_backup_location'] }/log_shipping"

include_recipe "TheCheftacularCookbook::db_prepare_storage_backups_volume"

directory "#{ node['main_backup_location'] }/log_shipping" do
  user      node['cheftacular']['deploy_user']
  group     node['cheftacular']['deploy_user']
  mode      "777"
  recursive true
end

unless node['postgresql']['rebased_from_production']
  include_recipe "TheCheftacularCookbook::db_rebase_data_directory_from_production"
end

db_slaves, master_hash = [], {}

data_bag_item('production', 'addresses')['addresses'].each do |serv_hash|
  if serv_hash['descriptor'].include?('dbmaster') 

    #capture the master's PRIVATE ipaddress
    master_hash = serv_hash

    break
  end
end

template "#{ node['postgresql']['config']['data_directory'] }/recovery.conf" do
  source 'log_shipping_recovery.conf.erb'
  owner  'postgres'
  group  'postgres'
  mode   '0744'
  variables(
    master_ip_address:             master_hash['address'],
    replication_password:          Chef::EncryptedDataBagItem.load( 'production', 'chef_passwords', node['secret']).to_hash["pg_pass"],
    filesystem_pg_backup_location: node['filesystem_pg_backup_location']
  )
end
