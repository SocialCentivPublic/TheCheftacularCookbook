mount_name  = "#{ node['hostname'].gsub('-','_') }_mongo"
volume_hash = node['TheCheftacularCookbook']['volume_config']['mongodb']

sub_directories_hash = {
  "mongodb" => { mode: '755', recursive: true }
}

TheCheftacularCookbook_business_volume mount_name do
  primary_directory "/mnt/mongo"
  sub_directories sub_directories_hash
  size (volume_hash.has_key?("#{ node.chef_environment }_size") ? volume_hash["#{ node.chef_environment }_size"] : volume_hash['default_size'])
  type (volume_hash.has_key?("#{ node.chef_environment }_type") ? volume_hash["#{ node.chef_environment }_type"] : volume_hash['default_type'])
end
