#!/usr/bin/env ruby

procs = `ps aux`
running_puma, running_nginx = false, false

procs.each_line do |proc|
  running_puma  = true if proc.include?('puma') 
  
  running_nginx = true if proc.include?('nginx')
end

case
when !running_puma && !running_nginx                             then puts 'WARNING - Puma and Nginx are NOT running!' ; exit 2
when running_puma && !running_nginx                              then puts 'WARNING - Nginx is NOT running!' ; exit 2
when !running_puma && running_nginx                              then puts 'WARNING - Puma is NOT running!' ; exit 2
when running_puma && running_nginx && `curl localhost`.empty?    then puts 'WARNING - Puma and Nginx are running but are not returning web requests!' ; exit 2
when running_puma && running_nginx && !(`curl localhost`.empty?) then puts "OK - Puma and Nginx are fully operational." ; exit 0
end
