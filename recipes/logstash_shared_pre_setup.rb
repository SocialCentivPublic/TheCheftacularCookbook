
elasticsearch_hosts = [] 

data_bag_item('production', 'addresses')['addresses'].each do |serv_hash|
  next unless serv_hash['name'].include?('logs')

  elasticsearch_hosts << serv_hash['address']
end

node.default['elkstack']['shared_variables'] = {
  output_lumberjack_port:  5960,
  output_lumberjack_hosts: elasticsearch_hosts,
  elasticsearch_ip:        elasticsearch_hosts.join(','),
  elasticsearch_protocol:  'transport',
  chef_environment:        node.chef_environment,
  true_hostname:           node['hostname']
}
