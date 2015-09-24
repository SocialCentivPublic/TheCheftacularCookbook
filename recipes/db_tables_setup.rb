#[TODO], chefify cap scripts that create initial dbs and users, possibly add seed / slave data. Implement checks so this is does not overwrite dbs

include_recipe "database::postgresql"

#one-off packages
package "pgBadger"

primary_connection_info = {}

node['loaded_applications'].each do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'
  
  primary_connection_info[repo_hash(app_role_name)['application_database_user']] ||= {
    host: '127.0.0.1',
    port: 5432,
    username: repo_hash(app_role_name)['application_database_user'],
    password: Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret']).to_hash["pg_pass"]
  }
end

node.set['postgres_connection_info'] = {
  host: '127.0.0.1',
  port: 5432,
  username: 'postgres',
  password: node['postgresql']['password']['postgres'] #this is created by postgresql::server
}

[node['cheftacular']['deploy_user'], node['primary_db_user']].each do |user|
  postgresql_database_user user do
    connection node['postgres_connection_info']

    password primary_connection_info[:password]
    action :create
  end
end

node['loaded_applications'].each do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'

  postgresql_database "#{ app_name }_#{ node.chef_environment }" do
    connection node['postgres_connection_info']
    template    'template0' #enables utf8 encoding
    collation   'en_US.UTF-8'
    encoding    'UTF8'
    tablespace  'DEFAULT'
    connection_limit '-1'
    owner       node['primary_db_user']

    action :create
  end

  postgresql_database_user node['primary_db_user'] do
    connection node['postgres_connection_info']

    database_name "#{ app_name }_#{ node.chef_environment }"
    privileges    [:all]
    action        :grant
  end

  node['additional_db_schemas'].each do |schema_hash|
    if node.chef_environment == schema_hash['environment']
      postgresql_database "#{ app_name }_#{ schema_hash['environment'] }" do
        connection node['postgres_connection_info']
        sql        "CREATE SCHEMA IF NOT EXISTS #{ schema_hash['schema_name'] } AUTHORIZATION #{ node['primary_db_user'] }"
        action     :query
      end
    end
  end
end

node['loaded_applications'].each do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'

  [node['cheftacular']['deploy_user'], node['primary_db_user']].each do |user|
    postgresql_database "#{ app_name }_#{ node.chef_environment }" do
      connection node['postgres_connection_info']
      sql        "ALTER ROLE #{ user } with SUPERUSER CREATEDB CREATEROLE"
      action     :query
    end
  end
end
