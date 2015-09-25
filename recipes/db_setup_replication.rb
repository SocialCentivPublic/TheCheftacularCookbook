ruby_block "set_replication_attrs_at_execute_time_onslave_if_rep_file_exists" do
  block do
    node.set['postgresql']['config']['hot_standby'] = 'on'
  end

  only_if { ::File.exists?("#{ node['postgresql']['config']['data_directory'] }/setup_replication.sh") }
end

if node['roles'].include?('db_primary')
  #https://www.digitalocean.com/community/tutorials/how-to-set-up-master-slave-replication-on-postgresql-on-an-ubuntu-12-04-vps
  rep_password = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["pg_pass"]

  #Query isn't running, needs to be fixed or run manually.
  postgresql_database 'setup_replication' do
    connection node['postgres_connection_info']
    sql        "CREATE USER rep REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD '#{ rep_password }';"
    action     :query
  end

  db_slaves = []

  #TODO Refactor to look for number of replication based roles?
  node['addresses'][node.chef_environment].each do |serv_hash|
    next unless serv_hash['descriptor'].include?('dbslave') 

    #capture each slave's PRIVATE ipaddress
    db_slaves << serv_hash
  end

  ruby_block "set_replication_attrs_at_execute_time" do
    block do
      #we dont want this run if theres no slaves
      if db_slaves.length >= 1
        #these sets will be run twice if they were not in this loop, once at compile time and again at run time, the compile time will screw up the postgres cookbook

        node.set['postgresql']['config']['wal_level']       = 'hot_standby'
        node.set['postgresql']['config']['archive_mode']    = 'on'
        node.set['postgresql']['config']['archive_command'] = 'cd .'
        node.set['postgresql']['config']['max_wal_senders'] = db_slaves.length+2
      end
    end
  end

elsif node['roles'].include?('db_slave') && !node['postgresql']['config']['hot_standby']

  include_recipe "TheCheftacularCookbook::db_rebase_data_directory_from_production"

  #this WILL cause the recipe to fail if not set this way
  ruby_block "set_replication_attrs_at_execute_time_onslave" do
    block do
      node.set['postgresql']['config']['hot_standby'] = 'on'
    end
  end
end

service "postgresql" do
  action :restart
end

=begin
node.set_unless['setup_slaves'] = {}

db_slaves.each do |slave_hash|
  unless node['setup_slaves'][slave_hash['address']]

    postgresql_database 'start_replication_backup' do
      connection node['postgres_connection_info']
      sql        "pg_start_backup('initial_backup');"
      action     :query
    end

    target_dir_arr = node['postgresql']['config']['data_directory'].split('/')
    target_dir = target_dir_arr[0..(target_dir_arr.length-2)].join('/')

    execute "start_replication" do
      user    "postgres"
      command "rsync -cva --inplace --exclude=*pg_xlog* #{ node['postgresql']['config']['data_directory'] } #{ slave_hash['address'] }:#{ target_dir }"
    end

    postgresql_database 'stop_replication_backup' do
      connection node['postgres_connection_info']
      sql        "select pg_stop_backup();"
      action     :query
    end

    node.set['setup_slaves'][slave_hash['address']] = true
  end
end
=end