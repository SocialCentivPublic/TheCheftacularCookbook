
include_recipe "TheCheftacularCookbook::db_fetch_backups_setup"

cookbook_file "/root/backup_management.rb" do
  source 'backup_management.rb'
  owner  'root'
  group  'root'
  mode   '0755'
end


cron_commands = []

if data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]['restore_backups']
  node['loaded_applications'].each_key do |app_role_name|
    next unless has_repo_hash?(app_role_name)
    next unless repo_hash(app_role_name)['database'] == 'mongodb'

    cron_commands << "ruby /root/backup_management.rb /mnt/postgresbackups/backups " +
      "#{ node['environment_name'] } #{ get_current_applications({'database' => 'mongodb'}).join(',') } " +
      "#{ Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["mongo_pass"] } " +
      "#{ repo_hash(app_role_name)['application_database_user'] } mongodb > /root/restore_mongodb.log 2>&1"
  end

  cron "restore_from_production_mongo_database" do
    minute  "45"
    hour    "11"
    user    "root"
    command "service mongodb stop && #{ cron_commands.join(' && ') } && service mongodb start"
    action :create
  end
else
  cron "restore_from_production_mongo_database" do
    action :delete
  end
end
