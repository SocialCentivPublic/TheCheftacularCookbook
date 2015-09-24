
check_file = "/home/#{ node['cheftacular']['deploy_user'] }/#{ node['TheCheftacularCookbook']['swap']['check_file_name'] }"

execute "initialize_swap" do
  command "dd if=/dev/zero of=#{ node['TheCheftacularCookbook']['swap']['path'] } bs=#{ node['TheCheftacularCookbook']['swap']['bs'] } count=#{ node['TheCheftacularCookbook']['swap']['count'] }"
  user    "root"
  not_if  { ::File.exists?(check_file) }
end

execute "create_swap" do
  command "mkswap #{ node['TheCheftacularCookbook']['swap']['path'] }"
  user    "root"
  not_if  { ::File.exists?(check_file) }
end

execute "activate_swap" do
  command "swapon #{ node['TheCheftacularCookbook']['swap']['path'] }"
  user    "root"
  not_if  { ::File.exists?(check_file) }
end

execute "update_fstab_for_swap" do
  command "echo '#{ node['TheCheftacularCookbook']['swap']['path'] }   none            swap    sw              0       0' >> /etc/fstab"
  user    "root"
  not_if  { ::File.exists?(checkfile) }
end

execute "update_stsctl_for_swap" do
  command "sed -i \"s/vm.swappiness = 0/vm.swappiness = #{ node['TheCheftacularCookbook']['swap']['swappiness'] }/\" /etc/sysctl.conf"
  user    "root"
  not_if  { ::File.exists?(checkfile) }
end

file checkfile do
  owner   node['cheftacular']['deploy_user']
  group   node['cheftacular']['deploy_user']
  mode    "0744"
  content "echo setup"
end
