
infrastructure_handlers, critical_handlers, deployment_handlers, ci_handlers, query_handlers = get_slack_handler_names

sensu_check "dns_status" do
  command     "check-dns.rb -d #{ data_bag_item( node.chef_environment, 'config').to_hash[node['environment_name']]['tld'] }"
  handlers    critical_handlers
  subscribers ["sensu_server"]
end

sensu_check "keepalive" do
  command     "check-ping.rb -h #{ node['sensu']['local_ip_address'] }"
  handlers    ["chef_node"]
  subscribers ["all"]
  additional(occurrences: [1, 10, 100, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 20000])
end

sensu_check "check-chef-client" do
  command     "check-chef-client.rb"
  handlers    (infrastructure_handlers + deployment_handlers)
  subscribers ["all"]
end

sensu_check "haproxy_status" do
  command     "check-haproxy.rb -P 22002 -S http://localhost -A -q \"\""
  handlers    infrastructure_handlers
  subscribers ["haproxy"]
end

sensu_check "cleanup-chef-node" do
  command     "sudo /opt/sensu/embedded/bin/ruby /etc/sensu/plugins/cleanup-chef-node.rb"
  handlers    []
  subscribers ["sensu_server"]
  interval    60
end

sensu_check "check-disk-fail" do
  command     "sudo /etc/sensu/plugins/check-disk-fail.rb"
  handlers    (infrastructure_handlers + critical_handlers)
  subscribers ["all"]
  interval    60
end

sensu_check "check-disk" do
  command     "check-disk.rb"
  handlers    infrastructure_handlers
  subscribers ["all"]
  interval 60
end

sensu_check "check-entropy" do
  command     "sudo /etc/sensu/plugins/check-entropy.rb"
  handlers    infrastructure_handlers
  subscribers ["all"]
  interval 60
end

sensu_check "check-fs-writable" do
  command     "check-fs-writable.rb -d /etc/sensu"
  handlers    infrastructure_handlers
  subscribers ["all"]
  interval    60
end

sensu_check "check-db-fs-writable" do
  command     "sudo /etc/sensu/plugins/check-fs-writable.rb -d /mnt/postgresqldata"
  handlers    infrastructure_handlers
  subscribers ["db"]
  interval    60
end

sensu_check "check-swap-percentage" do
  command     "sudo /etc/sensu/plugins/check-swap-percentage.sh -w 80 -c 90"
  handlers    infrastructure_handlers
  subscribers ["all"]
  interval    60
end
