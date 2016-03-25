
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
default['elkstack']['config']['lumberjack_data_bag'] = 'lumberjack' #this is the actual default
