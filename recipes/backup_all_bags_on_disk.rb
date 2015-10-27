include_recipe "TheCheftacularCookbook"

node.set['bag_backup_location'] = "#{ node['main_backup_location'] }/bag_backups"

directory node['bag_backup_location'] do
  user  node['cheftacular']['deploy_user']
  group node['cheftacular']['deploy_user']
  mode  "0755"
end

file "#{ node['bag_backup_location'] }/default_authentication.json" do
  owner   node['cheftacular']['deploy_user']
  group   node['cheftacular']['deploy_user']
  content Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret']).to_hash.to_json
  mode    '0644'
end

data_bag_item( 'default', 'environment_config').to_hash.each_pair do |env, env_hash|
  next if env =~ /id|chef_type|data_bag/
  
  Chef::Log.info("Preparing to store log hashes for #{ env }\n(#{ env_hash })")

  directory "#{ node['bag_backup_location'] }/#{ env }" do
    user  node['cheftacular']['deploy_user']
    group node['cheftacular']['deploy_user']
    mode  "0755"
  end

  file "#{ node['bag_backup_location'] }/#{ env }/audit_#{ Time.now.strftime("%Y%mweek%V") }.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content data_bag_item( env, 'audit').to_json
    mode    '0644'
  end if env_hash['bags'].include?('audit_bag')

  file "#{ node['bag_backup_location'] }/#{ env }/chef_passwords.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content Chef::EncryptedDataBagItem.load( env, 'chef_passwords', node['secret']).to_hash.to_json
    mode    '0644'
  end if env_hash['bags'].include?('chef_passwords_bag')

  file "#{ node['bag_backup_location'] }/#{ env }/server_passwords.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content Chef::EncryptedDataBagItem.load( env, 'server_passwords', node['secret']).to_hash.to_json
    mode    '0644'
  end if env_hash['bags'].include?('server_passwords_bag')

  file "#{ node['bag_backup_location'] }/#{ env }/addresses.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content data_bag_item( env, 'addresses').to_json
    mode    '0644'
  end if env_hash['bags'].include?('addresses_bag')

  file "#{ node['bag_backup_location'] }/#{ env }/config.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content data_bag_item( env, 'config').to_json
    mode    '0644'
  end if env_hash['bags'].include?('config_bag')

  file "#{ node['bag_backup_location'] }/#{ env }/logs_#{ Time.now.strftime("%Y%mweek%V") }.json" do
    owner   node['cheftacular']['deploy_user']
    group   node['cheftacular']['deploy_user']
    content data_bag_item( env, 'logs').to_json
    mode    '0644'
  end if env_hash['bags'].include?('logs_bag')
end
