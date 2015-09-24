class Chef
  class Recipe
    def return_application_defaults_as_hash(name, mode, role_name, ret_hash={})
      #find the db_master's data

      configs  = data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]
      revision = configs['app_revisions'].has_key?(name) ? configs['app_revisions'][name] : configs['default_revision']
      revision = nil if revision == '<use_default>' #TODO refactor

      revision = case
                 when revision.nil? && node.chef_environment == 'devstaging'  then 'devstaging'
                 when revision.nil? && node.chef_environment == 'staging'     then 'staging'
                 when revision.nil? && node.chef_environment == 'production'  then 'master'
                 when revision.nil? && node.chef_environment == 'test'        then 'devstaging'
                 when revision.nil? && node.chef_environment == 'datastaging' then 'master'
                 when revision.nil? && !node[name]['repo_branch'].nil?        then node[name]['repo_branch']
                 end

      node.set[name]['repo_branch']           = revision #set this so the above checks work
      ret_hash["path"]                        = node['base_application_location'] + "/#{ name }"
      ret_hash["shared_path"]                 = ret_hash["path"] + "/shared"
      ret_hash["current_path"]                = ret_hash["path"] + "/current"
      node.set[name]['current_path']          = ret_hash['current_path']
      ret_hash["repo_branch"]                 = revision
      ret_hash['repo_group']                  = node['TheCheftacularCookbook']['organization_name']
      ret_hash['pg_connection']               = true if mode =~ /ruby_on_rails/
      ret_hash["server_url"]                  = node_address_hash['dn']
      ret_hash['database_master']             = database_master_to_hash
      ret_hash['key_data']                    = Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret']).to_hash
      ret_hash['pg_pass']                     = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["pg_pass"] if mode =~ /ruby_on_rails/
      ret_hash['local_db_dn']                 = 'local.db.' + data_bag_item( node.chef_environment, 'config').to_hash[node.chef_environment]['tld']
      ret_hash['db_master_node']              = node['ipaddress'] == ret_hash['database_master']['public'] ? 'localhost' : local_db_dn
      ret_hash['db_master_node']              = 'localhost' if node['roles'].include?('sensu_build_db') || node['roles'].include?('db_slave') #build servers
      ret_hash['run_web']                     = node['roles'].include?('web')
      ret_hash['is_sensu_build']              = node['roles'].include?('sensu_build_db')
      ret_hash['db_user']                     = repo_hash[role_name]['application_database_user'] if repo_hash[role_name].has_key('application_database_users')
      ret_hash['db_attrs']                    = {}
      ret_hash['db_attrs']['template']        = 'template0' if node['roles'].include?('sensu_build_db')
      ret_hash['syms']                        = {}
      ret_hash['syms']['config/database.yml'] = 'config/database.yml'
      ret_hash                                = split_environment_setup(ret_hash)
      ret_hash['puma_pg_worker_boot']         = "require \"active_record\"\n" +
          "  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished\n" +
          "  ActiveRecord::Base.establish_connection(YAML.load_file(\"#{ app_hash['current_path'] }/config/database.yml\")[\"#{ node['environment_name'] }\"])"


      ret_hash
    end

    def split_environment_setup app_hash, test_env=''
      roles_to_environments = {}

      node['cheftacular']['run_list_environments'].each_value do |env_hash|
        env_hash.each_pair do |role_name, env_name|
          test_env = env_name if node['roles'].include?(role_name)
        end
      end

      return app_hash if test_env.blank?

      test_branch = test_env.split('split').join('split-')

      node.set[name]['repo_branch']           = test_branch
      app_hash['repo_branch']                 = test_branch
      node.force_override['environment_name'] = test_env
    end
  end
end
