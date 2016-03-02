
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
    'database' => repo_h['repo_name']
  }
end

node.set['mongodb']['users'] = mongodb_users

node.set['mongodb']['config']['authorization'] = 'enabled'

include_recipe "mongodb"
