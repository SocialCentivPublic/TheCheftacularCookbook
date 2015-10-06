#https://www.digitalocean.com/community/tutorials/how-to-set-up-master-slave-replication-on-postgresql-on-an-ubuntu-12-04-vps
#this recipe should always be run AFTER db

db_slaves, master_hash = [], {}

node['addresses'][node.chef_environment].each do |serv_hash|
  if serv_hash['descriptor'].include?('dbmaster') 

    #capture the master's PRIVATE ipaddress
    master_hash = serv_hash

  elsif serv_hash['descriptor'].include?('dbslave')
    db_slaves << serv_hash unless node['ipaddress'] == serv_hash['public']
  end
end

template "#{ node['postgresql']['config']['data_directory'] }/recovery.conf" do
  source 'recovery.conf.erb'
  owner  'postgres'
  group  'postgres'
  mode   '0744'
  variables(
    master_ip_address:    master_hash['address'],
    replication_password: Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["pg_pass"]
  )
end

include_recipe "postgresql::server"