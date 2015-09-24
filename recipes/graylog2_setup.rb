#TODO WORK IN PROGRESS

include_recipe "TheCheftacularCookbook"

node.set['java']['jdk_version'] = '7'

node.set['elasticsearch']['version'] = '1.3.4'
node.set['elasticsearch']['cluster']["name"] = "graylog2"

include_recipe "TheCheftacularCookbook::graylog2_secrets"

node.set['graylog2']['server']['java_opts']        = "-Djava.net.preferIPv4Stack=true"
node.set['graylog2']['web']['timezone']            = "Central Time (US & Canada)"

include_recipe "java"
include_recipe "elasticsearch"

if node['graylog2_setup_elastic_search']
  include_recipe "mongodb"
  include_recipe "graylog2"
  include_recipe "graylog2::server"
  include_recipe "graylog2::authbind"
  include_recipe "graylog2::web"

  sleep 240

  include_recipe "graylog2::api_access"

  include_recipe "nginx"

  environment_tld = data_bag_item(node.chef_environment, 'config').to_hash[node['environment_name']]['tld']

  template "/etc/nginx/sites-available/default" do
    source 'general_sites_available.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    variables(
      name:       "local.logs.#{ environment_tld }",
      base_name:  'logs',
      log_dir:    node['nginx']['log_dir'],
      target_url: 'http://localhost:9000'
    )
    if ::File.exists?("#{node['nginx']['dir']}/sites-enabled/default")
      notifies :reload, 'service[nginx]'
    end
  end
end

#elasticsearch does not finish starting until the delayed start is triggered from the cookbook, the initial deploy must be run twice
node.set['graylog2_setup_elastic_search'] = true
