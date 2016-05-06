
# These steps blank out all of the inputs for logstash which effectively gives it nothing to send

agent_name_array    = []
agent_hash          = {}

node['TheCheftacularCookbook']['logstash']['agent_role_maps'].each_pair do |role_name, role_hash|
  next if !node['roles'].include?(role_name) && role_name != 'default'
  next if role_hash.has_key?('not_on_role') && node['roles'].include?(role_hash['not_on_role'])

  role_hash.each_pair do |agent_collector_name, agent_collector_hash|
    next if agent_collector_name =~ /not_on_role/

    agent_hash[agent_collector_name] = {
      'name'      => agent_collector_name,
      'source'    => 'logstash/input_blank.conf.erb',
      'cookbook'  => 'TheCheftacularCookbook',
      'variables' => {}
    }

    agent_name_array << agent_collector_name
  end
end

node.set['elkstack']['config']['custom_logstash'] = agent_hash
node.set['elkstack']['config']['custom_logstash']['name'] = agent_name_array

include_recipe "java"
include_recipe "elkstack::agent"
