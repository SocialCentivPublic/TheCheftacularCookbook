
include_recipe "TheCheftacularCookbook"

#If the node has a role, use the role to populate the HA proxy's addresses [TODO]

tld = data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]['tld']

#TODO fix when working in staging
node.set['haproxy']['enable_default_http'] = !node['roles'].include?('https')
node.set['haproxy']['ssl_termination']     = node['roles'].include?('https')
node.set['haproxy']['x_forwarded_for']     = true

if node['roles'].include?('https')
  user "haproxy" do
    comment "haproxy system account"
    system true
    shell "/bin/false"
  end

  node.set['haproxy']['ssl_termination_pem_file'] = "/etc/ssl/private_haproxy/#{ tld }.pem"
  node.set['haproxy']['ssl_incoming_address']     = node['ipaddress']
  node.set['haproxy']['source']['use_openssl']    = true
  node.set['haproxy']['install_method']           = 'source'
  node.set['haproxy']['source']['version']        = '1.5.5' #only 1.5.4 and later support SSL termination
  node.set['haproxy']['source']['url']            = 'http://www.haproxy.org/download/1.5/src/haproxy-1.5.5.tar.gz'
  node.set['haproxy']['source']['checksum']       = 'e8d014e99a025e7d7878d402d30e03666c6d205c630a0b3c25f53a09fff4827c'

  node.set['haproxy']['admin']['username']        = node['TheCheftacularCookbook']['haproxy']['admin_username']
  node.set['haproxy']['admin']['password']        = node['TheCheftacularCookbook']['haproxy']['admin_password']

  target_dir_arr = node['haproxy']['ssl_termination_pem_file'].split('/')
  target_dir = target_dir_arr[0..(target_dir_arr.length-2)].join('/')

  directory target_dir do
    owner     'haproxy'
    group     'haproxy'
    mode      '700'
    recursive true
  end

  cookbook_file node['haproxy']['ssl_termination_pem_file'] do
    source   node['TheCheftacularCookbook']['haproxy']['ssl']['ssl_file_name'].gsub('ENVIRONMENT', node.chef_environment)
    owner    'haproxy'
    group    'haproxy'
    mode     '0644'
    cookbook node['TheCheftacularCookbook']['haproxy']['ssl']['cookbook_containing_ssl_certs']
    action  :create
  end

end
#LOGS GO TO /var/lib/haproxy/dev/log

server_arr = []

special_env = case 
              when node.chef_environment == node['environment_name'] then ''
              else                                                        '-' + node['environment_name']
              end

node['loaded_applications'].each_key do |app_role_name|
  node['addresses'][node.chef_environment].each do |serv_hash|
    next unless serv_hash['descriptor'] == "lb:#{ repo_hash(app_role_name)['repo_name'] }#{ special_env }"

    server_arr.push({
      'hostname' => serv_hash['name'],
      'ipaddress' => serv_hash['address'],
      'port' => 80,
      'ssl_port' => 443
    })
  end
end

#TODO REFACTOR
node['addresses'][node.chef_environment].each do |serv_hash|
  target_server, statement = {}, []

  node['TheCheftacularCookbook']['haproxy']['role_to_node_name_routing'].each_pair do |role_name, node_name|
    statement << "(node['roles'].include?(#{ role_name }) && serv_hash['name'] == #{ node_name })"
  end if node['TheCheftacularCookbook']['haproxy'].has_key?('role_to_node_name_routing')

  if Chef::Recipe.instance_eval(statement.join(' || '))
    target_server = { hostname: serv_hash['name'], ipaddress: serv_hash['address'] }
  else
    next
  end

  server_arr.push({
    'hostname' => target_server[:hostname],
    'ipaddress' => target_server[:ipaddress],
    'port' => 80,
    'ssl_port' => 443
  })
end

node.set['haproxy']['members'] = server_arr

include_recipe "haproxy::manual" unless node['skip_deploy'] == 'true'
