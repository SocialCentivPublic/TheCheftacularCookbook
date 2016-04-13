
#make the file readable for logstash
execute "chmod 644 /home/#{ node['cheftacular']['deploy_user'] }/.pry_history" do
  only_if { ::File.exists?("/home/#{ node['cheftacular']['deploy_user'] }/.pry_history") }
end
