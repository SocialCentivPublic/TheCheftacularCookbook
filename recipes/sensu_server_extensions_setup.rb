
cookbook_file "/etc/sensu/extensions/statsd.rb" do
  source 'sensu/extenstions/statsd.rb'
  owner  'sensu'
  group  'sensu'
  mode   '0755'
end
