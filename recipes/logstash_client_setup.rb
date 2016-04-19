
include_recipe "TheCheftacularCookbook"

include_recipe "TheCheftacularCookbook::logstash_shared_pre_setup"

agent_name_array    = []
agent_hash          = {}

node['TheCheftacularCookbook']['logstash']['agent_role_maps'].each_pair do |role_name, role_hash|
  next if !node['roles'].include?(role_name) && role_name != 'default'
  next if role_hash.has_key?('not_on_role') && node['roles'].include?(role_hash['not_on_role'])

  role_hash.each_pair do |agent_collector_name, agent_collector_hash|
    next if agent_collector_name =~ /not_on_role/

    agent_hash[agent_collector_name] = {
      'name'      => agent_collector_name,
      'source'    => (agent_collector_hash.has_key?('source') ? agent_collector_hash['source'] : 'logstash/input_file.conf.erb'),
      'cookbook'  => (agent_collector_hash.has_key?('cookbook') ? agent_collector_hash['cookbook'] : 'TheCheftacularCookbook'),
      'variables' => node['elkstack']['shared_variables'].merge(agent_collector_hash['variables'])
    }

    agent_name_array << agent_collector_name
  end
end

node.set['elkstack']['config']['custom_logstash'] = agent_hash
node.set['elkstack']['config']['custom_logstash']['name'] = agent_name_array

include_recipe "java"
include_recipe "elkstack::agent"

include_recipe "TheCheftacularCookbook::logstash_shared_post_setup"

#force restart of logstash so that it starts running immediately, doesn't always start on a first-run
logstash_service node['elkstack']['config']['logstash']['agent_name'] do
  action :restart
end
