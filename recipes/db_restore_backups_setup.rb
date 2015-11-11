
cookbook_file "/root/backup_management.rb" do
  source 'backup_management.rb'
  owner  'root'
  group  'root'
  mode   '0755'
end

cron_commands = [
  "ruby /root/backup_management.rb /mnt/postgresbackups/backups #{ node['environment_name'] } #{ get_current_applications.join(',') } #{ node['postgresql']['password']['postgres'] } postgres > /root/restore.log 2>&1"
]

if data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]['restore_backups']
  node['loaded_applications'].each_key do |app_role_name|
    next unless has_repo_hash?(app_role_name)
    next unless repo_hash(app_role_name)['database'] == 'postgresql'

    cron_commands << "cd #{ current_application_location(app_role_name) } && RAILS_ENV=#{ node['environment_name'] } bundle exec rake db:migrate"
  end

  cron "restore_from_production_database" do
    minute  "45"
    hour    "10" #5:30 am CST
    user    "root"
    command "#{ cron_commands.join(' && ') } && service postgresql restart"
    action :create
  end
else
  cron "restore_from_production_database" do
    action :delete
  end
end
