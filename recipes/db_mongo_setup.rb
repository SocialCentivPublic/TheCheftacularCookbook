
include_recipe "TheCheftacularCookbook"

include_recipe "TheCheftacularCookbook::db_mongo_volume_setup"

node.set['mongodb']['config']['dbpath'] = '/mnt/mongo/mongodb'

node.set['mongodb']['admin'] = {
  'username' => 'admin',
  'password' => Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["mongo_pass"],
  'roles' => %w(userAdminAnyDatabase dbAdminAnyDatabase),
  'database' => 'admin'
}

mongodb_users = []

node['loaded_applications'].each_key do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'mongodb'

  mongodb_users << {
    'username' => repo_hash(app_role_name)['application_database_user'],
    'password' => Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["mongo_pass"],
    'roles'    => %w(readWrite),
    'database' => repo_hash(app_role_name)['repo_name']
  }
end

node.set['mongodb']['users'] = mongodb_users

#Remember to remove this from the node itself when mongodb cookbook is updated to the yaml style configs
node.set['mongodb']['config']['auth'] = true
node.set['mongodb']['ruby_gems'] = {
  :mongo => '1.12.5',
  :bson_ext => nil
}

include_recipe "mongodb"
include_recipe "mongodb::mongo_gem"

execute "chown -R mongodb:nogroup #{ node['mongodb']['config']['dbpath'] }"
execute "chown -R mongodb:mongodb #{ node['mongodb']['config']['logpath'] }"

service 'mongodb' do
  action :restart
end

include_recipe "mongodb::user_management"
