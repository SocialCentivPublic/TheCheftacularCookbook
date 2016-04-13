module TheCheftacularCookbook
  module ApplicationDefault
    def return_application_defaults_as_hash(name, mode, role_name, ret_hash={}, org_name=nil)
      #find the db_master's data

      configs  = data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]

      if configs['app_revisions'].has_key?(name)
        revision = configs['app_revisions'][name].has_key?('revision')            ? configs['app_revisions'][name]['revision'] : nil
        org_name = configs['app_revisions'][name].has_key?('deploy_organization') ? configs['app_revisions'][name]['deploy_organization'] : nil
      end

      revision = nil if revision == '<use_default>'

      node['TheCheftacularCookbook']['chef_environment_to_app_repo_branch_mappings'].each_pair do |chef_env, app_env|
        revision = app_env if node.chef_environment == chef_env && revision.nil?
      end

      ret_hash['name']                        = name
      node.set[name]['repo_branch']           = revision #set this so the above checks work
      ret_hash["path"]                        = node['base_application_location'] + "/#{ name }"
      ret_hash["shared_path"]                 = ret_hash["path"] + "/shared"
      ret_hash["current_path"]                = ret_hash["path"] + "/current"
      node.set[name]['current_path']          = ret_hash['current_path']
      ret_hash["repo_branch"]                 = revision
      ret_hash['repo_group']                  = org_name.nil? ? node['TheCheftacularCookbook']['organization_name'] : org_name
      node.set[name]['repo_group']            = ret_hash['repo_group']
      ret_hash['pg_connection']               = true if repo_hash(role_name)['database'] == 'postgresql'
      ret_hash["server_url"]                  = node_address_hash['dn']
      ret_hash['database_master']             = database_master_to_hash
      ret_hash['key_data']                    = Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret']).to_hash
      ret_hash['pg_pass']                     = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["pg_pass"] if mode =~ /ruby_on_rails/
      ret_hash['mongo_pass']                  = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["mongo_pass"] if repo_hash(role_name)['sub_stack'] =~ /meteor/ 
      ret_hash['local_db_dn']                 = 'local.db.' + data_bag_item( node.chef_environment, 'config').to_hash[node.chef_environment]['tld']
      ret_hash['db_master_node']              = node['ipaddress'] == ret_hash['database_master']['public'] ? 'localhost' : ret_hash['local_db_dn']
      ret_hash['db_master_node']              = 'localhost' if node['roles'].include?('sensu_build_db') || node['roles'].include?('db_slave') #build servers
      ret_hash['run_web']                     = node['roles'].include?('web')
      ret_hash['is_sensu_build']              = node['roles'].include?('sensu_build_db')
      ret_hash['db_user']                     = repo_hash(role_name)['application_database_user'] if repo_hash(role_name).has_key?('application_database_user')
      ret_hash['db_environment']              = node['environment_name']
      ret_hash['runtime_environment']         = node['environment_name']
      ret_hash['db_name']                     = repo_hash(role_name).has_key?('use_other_repo_database') ? repo_hash(role_name)['use_other_repo_database'] : name
      ret_hash['db_attrs']                    = {}
      ret_hash['db_attrs']['template']        = 'template0' if node['roles'].include?('sensu_build_db')
      ret_hash['syms']                        = {}
      ret_hash['syms']['config/database.yml'] = 'config/database.yml' if mode =~ /ruby_on_rails/
      ret_hash['repo_computed_url']           = "https://#{ ret_hash['key_data']["git_OAuth"] }@github.com/#{ ret_hash['repo_group'] }/#{ name }.git"
      ret_hash['custom_nginx_configs']        = repo_hash(role_name).has_key?('custom_nginx_configs') ? repo_hash(role_name)['custom_nginx_configs'] : []
      ret_hash                                = split_environment_setup(ret_hash)
      ret_hash                                = override_setup(ret_hash, repo_hash(role_name)) if repo_hash(role_name).has_key?('db_env_node_bypass')
      ret_hash['puma_pg_worker_boot']         = "require \"active_record\"\n" +
          "  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished\n" +
          "  ActiveRecord::Base.establish_connection(YAML.load_file(\"#{ ret_hash['current_path'] }/config/database.yml\")[\"#{ ret_hash['runtime_environment'] }\"])"

      ret_hash
    end

    def split_environment_setup app_hash, test_env=''
      roles_to_environments = {}

      node['cheftacular']['run_list_environments'].each_value do |env_hash|
        env_hash.each_pair do |role_name, env_name|
          test_env = env_name if node['roles'].include?(role_name)
        end
      end

      return app_hash if test_env == ''

      test_branch = test_env.split('split').join('split-')

      node.set[name]['repo_branch']           = test_branch
      app_hash['repo_branch']                 = test_branch
      node.force_override['environment_name'] = test_env

      app_hash
    end

    def override_setup app_hash, _repo_hash
      _repo_hash['db_env_node_bypass'].each_pair do |original_env, original_env_hash|
        next if node.chef_environment != original_env

        if _repo_hash['sub_stack'] =~ /meteor/ 
          app_hash['mongo_pass'] = Chef::EncryptedDataBagItem.load( original_env_hash['environment_to_bypass_into'], 'chef_passwords', node['secret'])["mongo_pass"]
        elsif _repo_hash['database'] =~ /postgresql/
          app_hash['pg_pass'] = Chef::EncryptedDataBagItem.load( original_env_hash['environment_to_bypass_into'], 'chef_passwords', node['secret'])["pg_pass"]
        end

        app_hash['local_db_dn']         = 'local.db.' + data_bag_item( original_env_hash['environment_to_bypass_into'], 'config').to_hash[original_env_hash['environment_to_bypass_into']]['tld']
        app_hash['database_master']     = database_master_to_hash(original_env_hash['environment_to_bypass_into'])
        app_hash['db_master_node']      = node['ipaddress'] == app_hash['database_master']['public'] ? 'localhost' : app_hash['local_db_dn']
        app_hash['db_environment']      = original_env_hash['environment_to_bypass_into']
        app_hash['runtime_environment'] = original_env_hash['environment_to_bypass_into']
      end

      app_hash
    end
  end
end
