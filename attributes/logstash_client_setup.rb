
default['logstash']['supervisor_gid'] = 'adm'
default['lostash']['beaver']['outputs'] = [{
  "rabbitmq" => {
    "exchange_type" => "direct",
    "exchange" => "logstash-exchange"
  }
}]
