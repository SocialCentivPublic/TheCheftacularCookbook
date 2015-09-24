
postgres_keys_arr = []

search(:node, "postgres_public_key:*") do |n|
  postgres_keys_arr << n['postgres_public_key'] unless n['ipaddress'] == node['ipaddress']
end

template "/var/lib/postgresql/.ssh/authorized_keys" do
  source 'postgres.authorized_keys.erb'
  owner  'postgres'
  group  'postgres'
  mode   '0664'
  variables(
    keys: postgres_keys_arr
  )
end
