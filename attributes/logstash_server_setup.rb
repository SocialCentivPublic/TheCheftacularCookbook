
#default['logstash']['install_rabbitmq'] = true
#default['logstash']['server']['inputs'] = [{
#  "rabbitmq" => {
#    "type" => "direct",
#    "host" => "127.0.0.1",
#    "exchange" => "logstash-exchange",
#    "key" => "logstash-key",
#    "exclusive" => false,
#    "durable" => false,
#    "auto_delete" => false
#  }
#}]
#default['kibana']['webserver'] = ''
#default['kibana']['user']      = 'nobody'
default['elkstack']['config']['kibana']['redirect'] = true
default['elkstack']['config']['backups']['enabled'] = false
default['elkstack']['config']['agent_protocol'] = 'lumberjack'
default['elkstack']['config']['lumberjack_data_bag'] = 'lumberjack' #this is the actual default
default['rsyslog']['port'] = '5959'
default['elkstack']['config']['cloud_monitoring']['enabled'] = false

default['kibana']['file']['config_template_cookbook'] = 'TheCheftacularCookbook'
default['kibana']['config']['default_app_id']         = 'visualize'

cmd = default['elkstack']['cloud_monitoring']

# port monitor for eleastic search http
# this port is not usually publicly accessible, disable by default
cmd['port_9200']['disabled'] = true
cmd['port_9200']['period'] = 60
cmd['port_9200']['timeout'] = 30
cmd['port_9200']['alarm'] = false

# port monitor for eleastic search transport
# this port is not usually publicly accessible, disable by default
cmd['port_9300']['disabled'] = true
cmd['port_9300']['period'] = 60
cmd['port_9300']['timeout'] = 30
cmd['port_9300']['alarm'] = false

# port monitor for logstash
cmd['port_5959']['disabled'] = true
cmd['port_5959']['period'] = 60
cmd['port_5959']['timeout'] = 30
cmd['port_5959']['alarm'] = false

# port monitor for nginx/kibana http
cmd['port_80']['disabled'] = true
cmd['port_80']['period'] = 60
cmd['port_80']['timeout'] = 30
cmd['port_80']['alarm'] = false

# port monitor for nginx/kibana https
cmd['port_443']['disabled'] = true
cmd['port_443']['period'] = 60
cmd['port_443']['timeout'] = 30
cmd['port_443']['alarm'] = false

# elasticsearch_{check name}
cmd['elasticsearch_cluster-health']['disabled'] = true
cmd['elasticsearch_cluster-health']['period'] = 60
cmd['elasticsearch_cluster-health']['timeout'] = 30
cmd['elasticsearch_cluster-health']['alarm'] = false