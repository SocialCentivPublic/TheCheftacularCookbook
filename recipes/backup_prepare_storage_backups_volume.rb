
mount_name  = "#{ node['hostname'].gsub('-','_') }_main_backup_storage"
volume_hash = node['TheCheftacularCookbook']['volume_config']['backup_server']

sub_directories_hash = {
  "backups"             => { mode: '777', recursive: true },
  "backups/main_backup" => { mode: '777', recursive: true }
}

TheCheftacularCookbook_business_volume mount_name do
  primary_directory "/mnt/backupmaster"
  sub_directories sub_directories_hash

  size (volume_hash.has_key?("#{ node.chef_environment }_size") ? volume_hash["#{ node.chef_environment }_size"] : volume_hash['default_size'])
  type (volume_hash.has_key?("#{ node.chef_environment }_type") ? volume_hash["#{ node.chef_environment }_type"] : volume_hash['default_type'])
end
