
node.set['nginx']['ssl'] = true

directory "/var/opt/nginx/certs" do
  user  "root"
  group "root"
  mode  "0755"
  recursive true
end

cookbook_file "/var/opt/nginx/certs/#{ node.chef_environment }.crt" do
  source   node['TheCheftacularCookbook']['nginx']['ssl']['ssl_crt_file_name'].gsub('ENVIRONMENT', node.chef_environment)
  owner    'root'
  group    'root'
  mode     '0755'
  cookbook node['TheCheftacularCookbook']['nginx']['ssl']['cookbook_containing_ssl_certs']
end

cookbook_file "/var/opt/nginx/certs/#{ node.chef_environment }.key" do
  source   node['TheCheftacularCookbook']['nginx']['ssl']['ssl_key_file_name'].gsub('ENVIRONMENT', node.chef_environment)
  owner    'root'
  group    'root'
  mode     '0755'
  cookbook node['TheCheftacularCookbook']['nginx']['ssl']['cookbook_containing_ssl_certs']
end

node.set['nginx']['conf_cookbook'] = 'TheCheftacularCookbook'
