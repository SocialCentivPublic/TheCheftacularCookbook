node.set['main_backup_location']  = '/mnt/postgresbackups/backups'

include_recipe "TheCheftacularCookbook::db_prepare_storage_backups_volume"

include_recipe "backup"

chef_gem "backup"

backup_nodes, store_with_string, db_string, long_term_backup_nodes = [], '', '', []

search(:node, "receive_backups:*") do |n|
  backup_nodes << address_hash_from_node_name(scrub_chef_environments_from_string(n['hostname'])) if n['receive_backups']
end

search(:node, "receive_long_term_backups:*") do |n|
  long_term_backup_nodes << address_hash_from_node_name(scrub_chef_environments_from_string(n['hostname'])) if n['receive_long_term_backups']
end

node['loaded_applications'].each_key do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'

  db_name = repo_hash(app_role_name).has_key?('short_database_name') ? repo_hash(app_role_name)['short_database_name'] : repo_hash(app_role_name)['repo_name']

  db_string << "database PostgreSQL, :#{ db_name } do |db|
      db.name = '#{ repo_hash(app_role_name)['repo_name'] }_#{ node.chef_environment }'
      db.username = '#{ repo_hash(app_role_name)['application_database_user'] }'
      db.host = 'localhost'
      db.password = '#{ Chef::EncryptedDataBagItem.load( node.chef_environment,"chef_passwords", node['secret']).to_hash["pg_pass"] }'
      db.additional_options = ['-Fc']
    end

    "
end

backup_nodes.each do |serv_hash|
  next if serv_hash.empty?
  store_with_string << "store_with SCP, :#{ serv_hash['name'] } do |server|
      server.username = '#{ node['cheftacular']['deploy_user'] }'
      server.ip   = '#{ serv_hash['address'] }'
      server.port = '22'
      server.path = '#{ node['main_backup_location'] }'
      server.keep = #{ node['short_term_backup_count'] }
    end
    
    "
end

long_term_backup_nodes.each do |serv_hash|
  next if serv_hash.empty?
  store_with_string << "store_with SCP, :#{ serv_hash['name'] } do |server|
      server.username = '#{ node['cheftacular']['deploy_user'] }'
      server.ip   = '#{ serv_hash['address'] }'
      server.port = '22'
      server.path = '#{ node['backupmaster_storage_location'] }'
      server.keep = #{ node['long_term_backup_count'] }
    end
    
    "
end

if node['TheCheftacularCookbook']['sensu']['slack_handlers']['slack_critical'].has_key?('token')
  slack_string << "notify_by Slack do |slack|
      slack.on_success = true
      slack.on_warning = true
      slack.on_failure = true

      # The integration token
      slack.webhook_url = 'https://hooks.slack.com/services/#{ node['TheCheftacularCookbook']['sensu']['slack_handlers']['slack_critical']['token'] }'

      # The username to display along with the notification
      slack.username = 'Postgresbackups'
    end

    "
end

backup_model :main_backup do
  description "Back up postgres production database"

  definition <<-DEF

    #{ db_string }

    #{ store_with_string }

    store_with Local do |local|
      local.path = '#{ node['main_backup_location'] }'
      local.keep = #{ node['local_db_backup_count'] }
    end

    #{ slack_string }
  DEF
end

#crontab to run psql command to stop wal replay before backup, then reenable when it's done
cron_commands = [
  "/bin/bash -l -c '/opt/chef/embedded/bin/backup perform -t main_backup --root-path #{ node['backup']['config_path'] }'"
]

cron_commands.insert(0, "su - postgres -c \"psql -c \\\"SELECT pg_xlog_replay_pause();\\\"\"") unless node['roles'].include?('db_primary')

cron "backup_cron" do
  minute  node['backup_cron']['minute']
  hour    node['backup_cron']['hour']
  user    "root"
  command cron_commands.join(' && ')
end

#ensure this occurs no matter what. Every now and then the above cron will fail to execute its last line
if node['roles'].include?('db_primary')
  cron "restart_pg_replication" do
    action :delete
  end
else
  cron "restart_pg_replication" do
    minute node['restart_pg_replication']['minute']
    hour   node['restart_pg_replication']['hour']
    user   "root"
    command "su - postgres -c \"psql -c \\\"SELECT pg_xlog_replay_resume();\\\"\""
  end
end

node.set['attribute_toggles']["#{ node.chef_environment }_backups_activated"] = true
