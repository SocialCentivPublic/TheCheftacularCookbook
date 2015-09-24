# stop the slave so we can start the replication process
execute "service postgresql stop"

# for some reason this does not work
#service "postgresql" do
#  Chef::Log.info("About to shut down postgresql")
#  action :stop
#end

execute "remove-psql-slave-datadir" do
  command "rm -rf #{ node['postgresql']['config']['data_directory'] }"
  only_if { ::File.exists?( node['postgresql']['config']['data_directory'] ) }
end

master_hash = {}

data_bag_item('production', 'addresses')['addresses'].each do |serv_hash|
  next unless serv_hash['descriptor'].include?('dbmaster') 

  #capture the master's PRIVATE ipaddress
  master_hash = serv_hash
end

target_dir_arr = node['postgresql']['config']['data_directory'].split('/')
target_dir = target_dir_arr[0..(target_dir_arr.length-2)].join('/')

#postgres must own the mounting directory for the next command
directory target_dir do
  user      "postgres"
  group     "admin"
  mode      "775"
  recursive true
end

execute "create-psql-slave-datadir" do
  user    "postgres"
  command "pg_basebackup -X s -D #{ node['postgresql']['config']['data_directory'] } -U postgres -h #{ master_hash['address'] } -R"
end

file "#{ node['postgresql']['config']['data_directory'] }/setup_replication.sh" do
  owner   "postgres"
  group   "postgres"
  mode    "0744"
  content "echo setup"
end

ruby_block "set_rebased_from_production" do
  block do
    node.set['postgresql']['rebased_from_production'] = true
  end
end
