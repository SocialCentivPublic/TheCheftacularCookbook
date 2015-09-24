
class Chef
  class Recipe
    def chef_version
      node['chef_packages']['chef']['version']
    end

    #parse the node's extra data from the addresses hash and return it
    def node_address_hash return_hash={}
      node['addresses'][node.chef_environment].each do |serv_hash|
        next unless serv_hash['public'] == node['ipaddress']

        return_hash = serv_hash
      end

      return_hash
    end

    #TODO REFACTOR FIND BETTER SOLUTION THAT CHECKS CHEF ENVIRONMENTS
    def scrub_chef_environments_from_string string
      envs = [
        "devstaging",
        "datastaging",
        "staging",
        "production",
        "test"
      ]

      string.gsub(/#{envs.join('|')}/, "").gsub('-',"")
    end

    def address_hash_from_node_name node_name, return_hash={}
      data_bag_item('default','addresses').to_hash.each_pair do |env, serv_arr|
        next if serv_arr.class != Array
        serv_arr.each do |serv_hash|
          next unless serv_hash['name'] == node_name

          return_hash = serv_hash
        end
      end

      return_hash
    end

    def node_domain
      dn_arr = node_address_hash['dn'].split('.')

      dn_arr[(dn_arr.length-2)..(dn_arr.length-1)].join('.')
    end

    def get_block_storage_hash name, return_hash={}
      ruby_block "get_block_storage_for_#{ name }" do 
        block do
          node[:rackspacecloud][:cbs][:attached_volumes].each do |device_hash|
            return_hash = device_hash if device_hash[:display_name] == name
          end
        end
      end

      return_hash
    end

    def get_current_applications mode='array', ret_hash={}
      node['loaded_applications'].each do |app_role_name|
        ret_hash[repo_hash[app_role_name]['repo_name']] = repo_hash[app_role_name]
      end

      case mode
      when 'array'
        return ret_hash.keys
      when 'hash'
        return ret_hash
      end
    end

    #TODO refactor to better solution
    def database_master_to_hash
      database_master_hash = {}

      node['addresses'][node.chef_environment].each do |serv_hash|
        next unless serv_hash['descriptor'].include?('dbmaster') 

        database_master_hash = serv_hash
      end
    end

    def repo_hash app_role_name
      node['cheftacular']['repositories'][app_role_name]
    end

    def has_repo_hash? app_role_name
      node['cheftacular']['repositories'].has_key?(app_role_name)
    end

    def current_application_location app_role_name
      node['base_application_location'] + '/' + repo_hash(app_role_name)['repo_name']
    end

    def role_has_service_name? app_role_name, service_name
      node['cheftacular']['repositories'][app_role_name].has_key?('application_tasks') &&
        node['cheftacular']['repositories'][app_role_name]['application_tasks'].has_key?(service_name)
    end

    def extract_delayed_job_services app_role_name, return_array=[]
      if node['cheftacular']['repositories'][app_role_name].has_key?('application_tasks')
        node['cheftacular']['repositories'][app_role_name]['application_tasks'].each_key do |service_name|
          return_array << service_name if service_name.include?('delayed_job')
        end
      end

      return_array
    end

    def get_current_path app_role_name, append_string=''
      node['base_file_path'] + '/' + repo_hash[app_role_name]['repo_name'] + '/current' + append_string
    end

    #general-infrastructure|critical|deployment|continuous-integration|slow-queries
    def get_slack_handler_names infrastructure_subscribers=[], critical_subscribers=[], deployment_subscribers=[], ci_subscribers=[], query_subscribers=[]
      node['TheCheftacularCookbook']['sensu']['slack_handlers'].each_pair do |handler_name, handler_hash|
        infrastructure_subscribers << handler_name if handler_hash['mode'].include?('general-infrastructure')
        critical_subscribers       << handler_name if handler_hash['mode'].include?('critical_subscribers')
        deployment_subscribers     << handler_name if handler_hash['mode'].include?('deployment_subscribers')
        ci_subscribers             << handler_name if handler_hash['mode'].include?('ci_subscribers')
        query_subscribers          << handler_name if handler_hash['mode'].include?('query_subscribers')
      end

      infrastructure_subscribers, critical_subscribers, deployment_subscribers, ci_subscribers, query_subscribers
    end

    def parse_queues_into_env_var_from_service task_hash, queue_arr=[]
      queue_arr << task_hash['queues']['default']

      if task_hash['queues'].has_key?(node['environment_name'])
        queue_arr << task_hash['queues'][node['environment_name']]
      end
      
      queue_arr = node['environment_name'] if node['TheCheftacularCookbook']['override_delayed_job_queues_on_split_environments']

      "QUEUES=#{ queue_arr.flatten.join(',') }"
    end
  end
end
