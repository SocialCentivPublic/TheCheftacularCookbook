
node['TheCheftacularCookbook']['sensu']['slack_handlers'].each_pair do |handler_name, handler_hash|
  content_hash = {
    token:     handler_hash['token'],
    team_name: handler_hash['team_name'],
    channel:   handler_hash['channel']
  }

  content_hash['message_prefix'] = handler_hash.has_key?('message_prefix') ? handler_hash['message_prefix'] : ''
  content_hash['surround']       = handler_hash.has_key?('surround')       ? handler_hash['surround']       : ''
  content_hash['bot_name']       = handler_hash.has_key?('bot_name')       ? handler_hash['bot_name']       : 'sensu'

  sensu_snippet handler_name do
    content content_hash
  end

  template "/etc/sensu/handlers/#{ handler_name }.rb" do
    source 'sensu_plugin_slack.rb.erb'
    owner  'sensu'
    group  'sensu'
    mode   '0755'
    variables(
      snippet_root: handler_name
    )
  end

  sensu_handler handler_name do
    type       "pipe"
    command    "/opt/sensu/embedded/bin/ruby /etc/sensu/handlers/#{ handler_name }.rb"
    severities ["warning", "critical"]
  end
end

sensu_snippet "chef" do
  content(
    server_url:  Chef::Config[:chef_server_url],
    client_name: Chef::Config[:node_name],
    client_key:  Chef::Config[:client_key],
    verify_ssl:  false
  )
end

sensu_snippet "logevent" do
  content(
    eventdir: "/var/log/sensu/events",
    keep:     10
  )
end

# Config file setup
cookbook_file "/etc/sensu/handlers/chef_node.rb" do
  source 'sensu/handlers/other/chef_node.rb'
  owner  'sensu'
  group  'sensu'
  mode   '0755'
end

cookbook_file "/etc/sensu/handlers/logevent.rb" do
  source 'sensu/handlers/debug/logevent.rb'
  owner  'sensu'
  group  'sensu'
  mode   '0755'
end

cookbook_file "/etc/sensu/handlers/show.rb" do
  source 'sensu/handlers/debug/show.rb'
  owner  'sensu'
  group  'sensu'
  mode   '0755'
end

cookbook_file "/etc/sensu/handlers/sensu.rb" do
  source 'sensu/handlers/remediation/sensu.rb'
  owner  'sensu'
  group  'sensu'
  mode   '0755'
end

#handler definitions

sensu_handler "chef_node" do
  type    "pipe"
  command "sudo /etc/sensu/handlers/chef_node.rb"
end

sensu_handler "remediator" do
  type    "pipe"
  command "sensu.rb"
end

sensu_handler "logevent" do
  type    "pipe"
  command "logevent.rb"
end

sensu_handler "show" do
  type    "pipe"
  command "show.rb"
end

sensu_handler "graphite" do
  type "tcp"
  socket(
    host: "local.graphite.#{ data_bag_item('production', 'config').to_hash['production']['tld'] }",
    port: 2003
  )
  mutator "only_check_output"
end
