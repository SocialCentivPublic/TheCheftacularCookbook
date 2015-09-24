
file_plugin_arr = [
  { name: 'check-chef-server.rb',                 location: 'chef' },
  { name: 'check-dns.rb',                         location: 'dns' },
  { name: 'metric-dirsize.rb',                    location: 'files' },
  { name: 'check-log.rb',                         location: 'logging' },
  { name: 'check-ping.rb',                        location: 'ping' },
  { name: 'check-procs.rb',                       location: 'processes' },
  { name: 'longest-running-query-metric.rb',      location: 'rails'},
  { name: 'check-longest-running-query.rb',       location: 'rails'},
  { name: 'check-rspec.rb',                       location: 'rspec' },
  { name: 'cgroup-metrics.sh',                    location: 'system' },
  { name: 'check-cpu.rb',                         location: 'system' },
  { name: 'check-disk-fail.rb',                   location: 'system' },
  { name: 'check-disk-health.sh',                 location: 'system' },
  { name: 'check-disk.rb',                        location: 'system' },
  { name: 'check-entropy.rb',                     location: 'system' },
  { name: 'check-fs-writable.rb',                 location: 'system' },
  { name: 'check-fstab-mounts.rb',                location: 'system' },
  { name: 'check-hardware-fail.rb',               location: 'system' },
  { name: 'check-load.rb',                        location: 'system' },
  { name: 'check-ntp.rb',                         location: 'system' },
  { name: 'check-ram.rb',                         location: 'system' },
  { name: 'check-swap-percentage.sh',             location: 'system' },
  { name: 'cpu-metrics.rb',                       location: 'system' },
  { name: 'disk-capacity-metrics.rb',             location: 'system' },
  { name: 'disk-metrics.rb',                      location: 'system' },
  { name: 'disk-usage-metrics.rb',                location: 'system' },
  { name: 'entropy-metrics.rb',                   location: 'system' },
  { name: 'interface-metrics.rb',                 location: 'system' },
  { name: 'ioping-metrics.rb',                    location: 'system' },
  { name: 'iostat-extended-metrics.rb',           location: 'system' },
  { name: 'load-metrics.rb',                      location: 'system' },
  { name: 'memory-metrics-percent.rb',            location: 'system' },
  { name: 'memory-metrics.rb',                    location: 'system' },
  { name: 'ntpdate-metrics.rb',                   location: 'system' },
  { name: 'ntpstats-metrics.rb',                  location: 'system' },
  { name: 'proc-status-metrics.rb',               location: 'system' },
  { name: 'vmstat-metrics.rb',                    location: 'system' },
  { name: 'postgres-alive.rb',                    location: 'thecheftacularcookbook' },
  { name: 'postgres-connections-metric.rb',       location: 'thecheftacularcookbook' },
  { name: 'postgres-dbsize-metric.rb',            location: 'thecheftacularcookbook' },
  { name: 'postgres-graphite.rb',                 location: 'thecheftacularcookbook' },
  { name: 'postgres-locks-metric.rb',             location: 'thecheftacularcookbook' },
  { name: 'postgres-replication.rb',              location: 'thecheftacularcookbook' },
  { name: 'postgres-statsbgwriter-metric.rb',     location: 'thecheftacularcookbook' },
  { name: 'postgres-statsdb-metric.rb',           location: 'thecheftacularcookbook' },
  { name: 'postgres-statsio-metric.rb',           location: 'thecheftacularcookbook' },
  { name: 'postgres-statstable-metric.rb',        location: 'thecheftacularcookbook' },
  { name: 'postgres-slave-replication-status.rb', location: 'thecheftacularcookbook' },
  { name: 'check-chef-client.rb',                 location: 'thecheftacularcookbook' },
  { name: 'check-test-suite.rb',                  location: 'thecheftacularcookbook' },
  { name: 'check-haproxy.rb',                     location: 'thecheftacularcookbook' },
  { name: 'check-jobs.rb',                        location: 'thecheftacularcookbook' },
  { name: 'check-rails-web.rb',                   location: 'thecheftacularcookbook' },
  { name: 'check-tail.rb',                        location: 'thecheftacularcookbook' },
  { name: 'cpu-pcnt-usage-metrics.rb',            location: 'thecheftacularcookbook' },
  { name: 'haproxy-metrics.rb',                   location: 'thecheftacularcookbook' },
  { name: 'cleanup-chef-node.rb',                 location: 'thecheftacularcookbook' },
]

sudo_commands = []

node['TheCheftacularCookbook']['sensu']['custom_checks'].each_pair do |name, data_hash|
  file_plugin_arr << { 
    name:     data_hash['check_file_name'].split('/').last, 
    location: data_hash['check_file_folder'],
    cookbook: data_hash['cookbook']
  }
end

file_plugin_arr.each do |plugin_hash|
  cookbook_file "/etc/sensu/plugins/#{ file_name }" do
    source   "sensu/plugins/#{ plugin_hash[:location] }/#{ file_name }"
    owner    'sensu'
    group    'sensu'
    mode     '0755'
    cookbook (plugin_hash.has_key?(:cookbook) ? plugin_hash[:cookbook] : 'TheCheftacularCookbook')
  end

  sudo_commands << "/etc/sensu/plugins/#{ file_name }"
end

sudo_commands << "/etc/sensu/handlers/chef_node.rb"
sudo_commands << "/etc/sensu/handlers/logevent.rb"
sudo_commands << "/usr/sbin/service"
sudo_commands << "/opt/sensu/embedded/bin/ruby"
sudo_commands << "/usr/bin/chef-client"
sudo_commands << "/bin/kill"
sudo_commands << node['TheCheftacularCookbook']['sensu']['custom_sensu_sudo_commands']

sudo "sensu" do
  user "sensu"
  runas "root"
  commands sudo_commands.flatten
  host "ALL"
  nopasswd true
end
