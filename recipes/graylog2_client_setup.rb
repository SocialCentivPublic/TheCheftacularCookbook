#TODO WORK IN PROGRESS

include_recipe "TheCheftacularCookbook"

include_recipe "TheCheftacularCookbook::graylog2_secrets"

environment_tld = data_bag_item(node.chef_environment, 'config').to_hash[node['environment_name']]['tld']

node.set[:graylog2][:rest][:listen_uri] = "local.logs.#{ environment_tld }"

include_recipe "graylog2"

graylog2_inputs "environment log" do
  input "{ \"title\": \"environment log\", \"type\":\"org.graylog2.inputs.syslog.udp.SyslogUDPInput\", \"global\": true, \"configuration\": { \"port\": 1514, \"allow_override_date\": true, \"bind_address\": \"#{ node['ipaddress']}\", \"store_full_message\": true, \"recv_buffer_size\": 1048576 } }"
end

