
include_recipe "simple_iptables"

simple_iptables_rule "system_accept" do
  rule [ # Allow all traffic on the loopback device
         "--in-interface lo",
         # Allow any established connections to continue, even
         # if they would be in violation of other rules.
         "-m conntrack --ctstate ESTABLISHED,RELATED",
         # Allow SSH
         "--proto tcp --dport 22",
       ]
  jump "ACCEPT"
end

node['TheCheftacularCookbook']['iptables']['additional_iptables_recipes'].each_value do |check_hash|
  include_recipe "#{ check_hash['cookbook'] }::#{ check_hash['filename_without_extension'] }"
end

role_maps = node['TheCheftacularCookbook']['iptables']['role_maps']

#================================ ACCEPT ALL PORTS ========================

simple_iptables_rule "ssh_accept" do
  rule "--proto tcp --dport 22"
  jump "ACCEPT"
end

simple_iptables_rule "http_accept" do
  rule [ "--proto tcp --dport 80",
         "--proto tcp --dport 443" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['web_servers'])

simple_iptables_rule "redis_accept" do
  rule [ "--proto tcp --dport 4567",
         "--proto tcp --dport 6379" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['sensu_server']) || node['roles'].include?(role_maps['sensu_client'])

simple_iptables_rule "rabbitmq_accept" do
  rule [ "--proto tcp --dport 5671",
         "--proto tcp --dport 5672",
         "--proto tcp --dport 5681",
         "--proto tcp --dport 15672" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['sensu_server']) || node['roles'].include?(role_maps['sensu_client'])

simple_iptables_rule "haproxy_accept" do
  rule [ "--proto tcp --dport 22002"]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['haproxy'])

########################################################## ACCEPT LOCAL PORTS ###########################################

simple_iptables_rule "graylog2_accept" do
  rule [ "-i eth1 --proto tcp --dport 514" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['graylog2_server'])

simple_iptables_rule "graphite_accept" do
  rule [ "-i eth1 --proto tcp --dport 2003",
         "-i eth1 --proto tcp --dport 2004",
         "-i eth1 --proto tcp --dport 7002" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['graphite_server'])

simple_iptables_rule "postgres_accept" do
  rule "-i eth1 --proto tcp --dport 5432"
  jump "ACCEPT"
end if node['roles'].include?(role_maps['database'])

simple_iptables_rule "graylog2_accept" do
  rule [ "-i eth1 --proto tcp --dport 12900" ]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['database'])

simple_iptables_rule "mongodb_accept" do
  rule ["-i eth1 --proto tcp --dport 27017"]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['mongodb'])

simple_iptables_rule "logstash_accept" do
  rule ["-i eth1 --proto tcp --dport 5959",
        "-i eth1 --proto tcp --dport 5960",
        "-i eth1 --proto tcp --dport 5961",
        "-i eth1 --proto tcp --dport 5962",
        "-i eth1 --proto tcp --dport 5963",
        "-i eth1 --proto tcp --dport 9292",
        "-i eth1 --proto tcp --dport 9200"]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['logstash_server'])

simple_iptables_rule "logstash_agent_accept" do
  rule ["-i eth1 --proto tcp --dport 5959",
        "-i eth1 --proto tcp --dport 5960",
        "-i eth1 --proto tcp --dport 5961",
        "-i eth1 --proto tcp --dport 5962",
        "-i eth1 --proto tcp --dport 5963"]
  jump "ACCEPT"
end if node['roles'].include?(role_maps['logstash_client'])


############################################## DROP INTERNET PORTS ############################################

simple_iptables_rule "graylog2_drop" do
  rule [ "-i eth0 --proto tcp --dport 514" ]
  jump "DROP"
end if node['roles'].include?(role_maps['graylog2_server'])

simple_iptables_rule "graphite_drop" do
  rule [ "-i eth0 --proto tcp --dport 2003",
         "-i eth0 --proto tcp --dport 2004",
         "-i eth0 --proto tcp --dport 7002" ]
  jump "DROP"
end if node['roles'].include?(role_maps['graphite_server'])

simple_iptables_rule "postgres_drop" do
  rule [ "-i eth0 --proto tcp --dport 5432" ]
  jump "DROP"
end if node['roles'].include?(role_maps['database'])

simple_iptables_rule "graylog2_drop" do
  rule [ "-i eth0 --proto tcp --dport 12900" ]
  jump "DROP"
end if node['roles'].include?(role_maps['graylog2_server'])

simple_iptables_rule "mongodb_drop" do
  rule ["-i eth0 --proto tcp --dport 27017"]
  jump "DROP"
end if node['roles'].include?(role_maps['mongodb'])

simple_iptables_rule "logstash_drop" do
  rule ["-i eth1 --proto tcp --dport 5959",
        "-i eth1 --proto tcp --dport 5960",
        "-i eth1 --proto tcp --dport 5961",
        "-i eth1 --proto tcp --dport 5962",
        "-i eth1 --proto tcp --dport 5963",
        "-i eth0 --proto tcp --dport 9292",
        "-i eth0 --proto tcp --dport 9200"]
  jump "DROP"
end if node['roles'].include?(role_maps['logstash_server'])

simple_iptables_rule "logstash_agent_drop" do
  rule ["-i eth0 --proto tcp --dport 5959",
        "-i eth0 --proto tcp --dport 5960",
        "-i eth0 --proto tcp --dport 5961",
        "-i eth1 --proto tcp --dport 5962",
        "-i eth1 --proto tcp --dport 5963"]
  jump "DROP"
end if node['roles'].include?(role_maps['logstash_client'])


simple_iptables_rule "system_log" do
  rule "--match limit --limit 5/min --jump LOG --log-prefix \"iptables denied: \" --log-level 7"
  jump false
end

simple_iptables_rule "local_ping" do
  rule [ "-i eth1 -p icmp --icmp-type echo-request",
         "-i eth1 -p icmp --icmp-type echo-reply" ]
  jump "ACCEPT"
end

# Reject packets other than those explicitly allowed
simple_iptables_policy "INPUT" do
  policy "DROP"
end

simple_iptables_policy "OUTPUT" do
  policy "ACCEPT"
end