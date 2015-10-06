#!/usr/bin/env ruby

procs = `ps aux`
running_chef_client = false
chef_procs = []

procs.each_line do |proc|
  running_chef_client  = true if proc.include?('chef-client') && !proc.include?('check-chef-client.rb') && !proc.include?('chef-client -d')
  chef_procs << proc if proc.include?('chef-client')
end

#this case is unique to chef daemons, we don't want notifications on deploys that happen at a set interval
running_chef_client = false if chef_procs.join(' ').include?('chef-client worker') && chef_procs.join(' ').include?('chef-client -d')

case
when !running_chef_client then puts 'Chef client process has completed or is no longer running.' ; exit 0
when running_chef_client  then puts 'Chef client process detected!' ; exit 1
end
