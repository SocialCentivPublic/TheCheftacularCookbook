#!/usr/bin/env ruby

procs          = `ps aux`
base_line      = '/etc/sensu/handlers/chef_node.rb'
sh_line        = "sh -c sudo #{ base_line }"
sudo_line      = "sudo #{ base_line }"
finished_procs = []
target_procs   = {}

procs.each_line do |proc|
  next unless proc.include?(base_line)
  next unless proc[/([\w]+){1}/] =~ /sensu|root/ #check the user calling process

  proc_id = proc[/([\d]+){1}/]

  target_procs[proc_id] = {}
  target_procs[proc_id]['line'] = case
                                  when proc.include?(sh_line)               then sh_line
                                  when proc.include?(sudo_line)             then sudo_line
                                  when proc.include?("ruby #{ base_line }") then "ruby #{ base_line }"
                                  end

  target_procs[proc_id]['cpu']  = proc[/([\d]+\.[\d]+){1}/].to_f
  target_procs[proc_id]['id']   = proc[/([\d]+){1}/]
end

target_procs.each_pair do |prc_id, proc_hash|
  next_proc = target_procs[target_procs.keys[target_procs.keys.index(prc_id)+1]]
  ruby_proc = target_procs[target_procs.keys[target_procs.keys.index(prc_id)+2]]

  next if next_proc.nil? || ruby_proc.nil?

  if next_proc['line'] == sudo_line && ruby_proc['line'] == "ruby #{ base_line }" && ruby_proc['cpu'] < 0.2
    puts "preparing to kill #{ prc_id } && #{ next_proc['id'] }"

    `kill #{ prc_id } && kill #{ next_proc['id'] }`
  end
end
