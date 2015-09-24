
cookbook_file "/root/cheftacular.yml" do
  source 'cheftacular.yml'
  owner  'root'
  group  'root'
  mode   '0755'
end

node['TheCheftacularCookbook']['sensu']['crons'].each_pair do |cron_name, cron_hash|
  command = cron_hash['create_log'] ? "#{ cron_hash['command'] } > /var/log/sensu/run_#{ cron_name }.log 2>&1" : cron_hash['command']

  cron cron_name do
    minute  cron_hash['minute']
    hour    cron_hash['hour']
    user    'root'
    command command
  end
end
