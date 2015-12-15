mount_name  = "#{ node['hostname'].gsub('-','_') }_backup_storage"
volume_hash = node['TheCheftacularCookbook']['volume_config']['database_backup']

node.set_unless['main_backup_location']  = '/mnt/postgresbackups/backups'
node.set_unless['backup']['config_path'] = "#{ node['main_backup_location'] }/backup_gem"
node.set_unless['backup']['model_path']  = "#{ node['backup']['config_path'] }/models"

sub_directories_hash = {
  "backups"             => { mode: '777', recursive: true },
  "backups/main_backup" => { mode: '777', recursive: true }
}

TheCheftacularCookbook_business_volume mount_name do
  primary_directory "/mnt/postgresbackups"
  sub_directories sub_directories_hash
  size (volume_hash.has_key?("#{ node.chef_environment }_size") ? volume_hash["#{ node.chef_environment }_size"] : volume_hash['default_size'])
  type (volume_hash.has_key?("#{ node.chef_environment }_type") ? volume_hash["#{ node.chef_environment }_type"] : volume_hash['default_type'])
end
