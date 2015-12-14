mount_name  = "#{ node['hostname'].gsub('-','_') }_mini_backup_storage"
volume_hash = node['TheCheftacularCookbook']['volume_config']['mini_backup']

sub_directories_hash = {
  "backups" => { mode: '777', recursive: true }
}

TheCheftacularCookbook_business_volume mount_name do
  primary_directory "/mnt/minibackup"
  sub_directories sub_directories_hash
  size (volume_hash.has_key?("#{ node.chef_environment }_size") ? volume_hash["#{ node.chef_environment }_size"] : volume_hash['default_size'])
  type (volume_hash.has_key?("#{ node.chef_environment }_type") ? volume_hash["#{ node.chef_environment }_type"] : volume_hash['default_type'])
end
