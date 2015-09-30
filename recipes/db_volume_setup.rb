mount_name  = "#{ node['hostname'].gsub('-','_') }"
volume_hash = node['TheCheftacularCookbook']['volume_config']['database']

sub_directories = { main: { not_if: 'cat /etc/passwd | grep postgres' } }
sub_directories = { main: { user: 'postgres', group: 'postgres', only_if: 'cat /etc/passwd | grep postgres' } } if node['roles'].include?('sensu_build_db')

TheCheftacularCookbook_business_volume mount_name do
  primary_directory "/mnt/postgresqldata"
  sub_directories sub_directories
  size (volume_hash.has_key?("#{ node.chef_environment }_size") ? volume_hash["#{ node.chef_environment }_size"] : volume_hash['default_size'])
  type (volume_hash.has_key?("#{ node.chef_environment }_type") ? volume_hash["#{ node.chef_environment }_type"] : volume_hash['default_type'])
end
