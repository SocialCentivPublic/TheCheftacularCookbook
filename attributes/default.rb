
default['cheftacular']                   = Chef::DataBagItem.load('default', 'cheftacular').to_hash
default['TheCheftacularCookbook']        = node['cheftacular']['TheCheftacularCookbook']
default['loaded_applications']           = {} #array of all app codebases that will be loaded onto a server. This array is populated further on in the code
default['environment_name']              = node.chef_environment
default['base_application_location']     = node['TheCheftacularCookbook']['base_application_location']
default['secret_path']                   = '/etc/chef/data_bag_key'
default['secret']                        = Chef::EncryptedDataBagItem.load_secret("#{ node['secret_path'] }")
default['additional_db_schemas']         = node['TheCheftacularCookbook']['additional_db_schemas']
default['default_rackspace_volume_size'] = node['TheCheftacularCookbook']['default_rackspace_volume_size']
default['backupmaster_storage_location'] = '/mnt/backupmaster/backups'

#Some defaults for chef-rvm
default['desired_ruby']             = node['cheftacular']['ruby_version'].gsub('ruby-','')
default['rvm']['default_ruby']      = "ruby-#{ node['desired_ruby'] }"
default['rvm']['user_default_ruby'] = "ruby-#{ node['desired_ruby'] }"
default['rvm']['rvm_home']          = "/home/#{ node['cheftacular']['deploy_user'] }/.rvm"
default['rvm']['user_installs'] = [
  {
    'user' => node['cheftacular']['deploy_user'],
    'default_ruby' => node['desired_ruby'],
    'rubies' => [ node['desired_ruby'],'ruby-1.9.3-p327'], #1.9.3-p327 is chef's default ruby, it needs to be in a place rvm can find it
    'global_gems' => [
      { 'name'    => 'bundler', 'version' => node['TheCheftacularCookbook']['bundler_version'] }
    ]
  }
]

env_path = "#{ node['rvm']['rvm_home'] }/gems/#{ node['rvm']['default_ruby'] }/bin:" +
"#{ node['rvm']['rvm_home'] }/gems/#{ node['rvm']['default_ruby'] }@global/bin:" + 
"#{ node['rvm']['rvm_home'] }/rubies/#{ node['rvm']['default_ruby'] }:" +
"#{ node['rvm']['rvm_home'] }/bin:" +
"usr/local/sbin:" +
"usr/local/bin:" +
"usr/bin:" +
"usr/sbin:" +
"/sbin:" +
"usr/games:" +
"/bin:" +
"usr/local/games:"

default['ruby-env'] = {
  "RAILS_ENV"=> node.chef_environment,
  "PATH"=> env_path,
  "GEM_PATH"=>"#{ node['rvm']['rvm_home'] }/gems/#{ node['rvm']['default_ruby'] }:#{ node['rvm']['rvm_home'] }/gems/#{ node['rvm']['default_ruby'] }@global",
  "GEM_HOME"=>"#{ node['rvm']['rvm_home'] }/gems/#{ node['rvm']['default_ruby'] }"
}

default['bundle_command']           = "/etc/profile.d/rvm.sh && /home/#{ node['cheftacular']['deploy_user'] }/.rvm/gems/#{ node['rvm']['default_ruby'] }@global/bin/bundle"
default['unsourced_bundle_command'] = node['bundle_command'].gsub('/etc/profile.d/rvm.sh && ', '')

default['authorization']['sudo']['include_sudoers_d'] = true

#TODO CHECK WITH BACKUP GEM AND RECIPES, ITS STUCK AT THIS
default[:rackspacecloud][:fog_version] = "1.28.0"
default['backup']['version']           = '4.1.10'