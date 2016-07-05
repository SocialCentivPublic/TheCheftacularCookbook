
instance_name = node['roles'].include?(node['TheCheftacularCookbook']['role_maps']['logstash_server']) ? node['elkstack']['config']['logstash']['instance_name'] : node['elkstack']['config']['logstash']['agent_name']

nginx_template = { 'nginx' => 'logstash/nginx.erb' }

logstash_pattern instance_name do
  templates           nginx_template
  templates_cookbook  'TheCheftacularCookbook'
  owner               'logstash'
  group               'logstash'
end

if node['roles'].include?(node['TheCheftacularCookbook']['role_maps']['logstash_nginx_logging'])
  group 'adm' do
    action :modify
    members 'logstash'
    append true
  end
end
