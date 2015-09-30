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
      ret_hash['pg_connection']               = true if mode =~ /ruby_on_rails/
      ret_hash["server_url"]                  = node_address_hash['dn']
      ret_hash['database_master']             = database_master_to_hash
      ret_hash['key_data']                    = Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret']).to_hash
      ret_hash['pg_pass']                     = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["pg_pass"] if mode =~ /ruby_on_rails/
      ret_hash['local_db_dn']                 = 'local.db.' + data_bag_item( node.chef_environment, 'config').to_hash[node.chef_environment]['tld']
      ret_hash['db_master_node']              = node['ipaddress'] == ret_hash['database_master']['public'] ? 'localhost' : ret_hash['local_db_dn']
      ret_hash['db_master_node']              = 'localhost' if node['roles'].include?('sensu_build_db') || node['roles'].include?('db_slave') #build servers
      ret_hash['run_web']                     = node['roles'].include?('web')
      ret_hash['is_sensu_build']              = node['roles'].include?('sensu_build_db')
      ret_hash['db_user']                     = repo_hash(role_name)['application_database_user'] if repo_hash(role_name).has_key?('application_database_users')
      ret_hash['db_environment']              = node['environment_name']
      ret_hash['db_name']                     = name
      ret_hash['db_attrs']                    = {}
      ret_hash['db_attrs']['template']        = 'template0' if node['roles'].include?('sensu_build_db')
      ret_hash['syms']                        = {}
      ret_hash['syms']['config/database.yml'] = 'config/database.yml' if mode =~ /ruby_on_rails/
      ret_hash['repo_computed_url']           = "https://#{ ret_hash['key_data']["git_OAuth"] }@github.com/#{ ret_hash['repo_group'] }/#{ name }.git"
      ret_hash['custom_nginx_configs']        = repo_hash(role_name).has_key?('custom_nginx_configs') ? repo_hash(role_name)['custom_nginx_configs'] : []
      ret_hash                                = split_environment_setup(ret_hash)
      ret_hash['puma_pg_worker_boot']         = "require \"active_record\"\n" +
          "  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished\n" +
          "  ActiveRecord::Base.establish_connection(YAML.load_file(\"#{ ret_hash['current_path'] }/config/database.yml\")[\"#{ node['environment_name'] }\"])"


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
    end
  end
end
