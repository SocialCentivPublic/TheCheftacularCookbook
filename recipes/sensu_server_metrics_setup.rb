
sensu_check "haproxy-metrics" do
  command     "/opt/sensu/embedded/bin/ruby /etc/sensu/plugins/haproxy-metrics.rb -P 22002 -c http://localhost -q \"\" --server-metrics"
  handlers    ["graphite"]
  interval    60
  type        "metric"
  subscribers node['TheCheftacularCookbook']['sensu']['haproxy_monitoring_roles']
  additional(occurences: 1)
end

sensu_check "cpu-metrics" do
  command     "cpu-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "cpu-pcnt-usage-metrics" do
  command     "sudo /etc/sensu/plugins/cpu-pcnt-usage-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "disk-capacity-metrics" do
  command     "sudo /etc/sensu/plugins/disk-capacity-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "disk-metrics" do
  command     "sudo /etc/sensu/plugins/disk-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "disk-usage-metrics" do
  command     "sudo /etc/sensu/plugins/disk-usage-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "entropy-metrics" do
  command     "sudo /etc/sensu/plugins/entropy-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "interface-metrics" do
  command     "sudo /etc/sensu/plugins/interface-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "load-metrics" do
  command     "sudo /etc/sensu/plugins/load-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "memory-percent-metrics" do
  command     "sudo /etc/sensu/plugins/memory-metrics-percent.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "memory-metrics" do
  command     "sudo /etc/sensu/plugins/memory-metrics.rb"
  handlers    ["graphite"]
  subscribers ["all"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end

sensu_check "ntpstats-metrics" do
  command     "sudo /etc/sensu/plugins/ntpstats-metrics.rb -h localhost"
  handlers    ["graphite"]
  subscribers ["web"]
  interval    60
  type        "metric"
  additional(occurrences: 1)
end
