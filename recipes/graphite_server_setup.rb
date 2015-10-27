
include_recipe "TheCheftacularCookbook"

node.set['graphite']['uwsgi']['listen_http'] = true
node.set['graphite']['user']                 = "graphite" #this cannot be changed sadly
node.set['graphite']['password']             = Chef::EncryptedDataBagItem.load( node.chef_environment, "chef_passwords", node['secret'])["graphite_pass"]

include_recipe "runit"
include_recipe "graphite::carbon"
include_recipe "graphite::_web_packages"

storage_dir = node['graphite']['storage_dir']

graphite_carbon_cache "default" do
  config ({
            enable_logrotation: true,
            user: "graphite",
            max_cache_size: "inf",
            max_updates_per_second: 500,
            max_creates_per_minute: 50,
            line_receiver_interface: "0.0.0.0",
            line_receiver_port: 2003,
            udp_receiver_port: 2003,
            pickle_receiver_port: 2004,
            enable_udp_listener: true,
            cache_query_port: "7002",
            cache_write_strategy: "sorted",
            use_flow_control: true,
            log_updates: false,
            log_cache_hits: false,
            whisper_autoflush: false,
            local_data_dir: "#{storage_dir}/whisper/"
          })
end

graphite_storage_schema "carbon" do
  config ({
            pattern: "^carbon\.",
            retentions: "60:90d"
          })
end

node['TheCheftacularCookbook']['graphite']['storage_schemas'].each_pair do |schema_name, schema_hash|
  if schema_hash.has_key?('names')
    schema_hash['names'].each do |schema|
      graphite_storage_schema "#{ schema }_#{ schema_name }" do
        config ({
          pattern: schema_hash['pattern'].gsub('SCHEMA_NAME', schema),
          retentions: schema_hash['retentions']
        })
      end
    end
  else
    graphite_storage_schema schema_name do
      config ({
        pattern: schema_hash['pattern'],
        retentions: schema_hash['retentions']
      })
    end
  end
end if node['TheCheftacularCookbook']['graphite'].has_key?('storage_schemas')

graphite_service "cache"

graphite_storage "/opt/graphite/storage"
graphite_storage "/srv/graphite/data"

base_dir = "#{node['graphite']['base_dir']}"

graphite_web_config "#{base_dir}/webapp/graphite/local_settings.py" do
  config({
           secret_key: node['TheCheftacularCookbook']['graphite']['secret_key'],
           time_zone: node['TheCheftacularCookbook']['graphite']['time_zone'],
           conf_dir: "#{base_dir}/conf",
           storage_dir: storage_dir,
           databases: {
             default: {
               # keys need to be upcase here
               NAME: "#{storage_dir}/graphite.db",
               ENGINE: "django.db.backends.sqlite3",
               USER: nil,
               PASSWORD: nil,
               HOST: nil,
               PORT: nil
             }
           }
         })
  notifies :restart, 'service[graphite-web]', :delayed
end

directory "#{storage_dir}/log/webapp" do
  owner node['graphite']['user']
  group node['graphite']['group']
  recursive true
end

execute "python manage.py syncdb --noinput" do
  user node['graphite']['user']
  group node['graphite']['group']
  cwd "#{base_dir}/webapp/graphite"
  creates "#{storage_dir}/graphite.db"
  notifies :run, "python[set admin password]"
end

# creates an initial user, doesn't require the set_admin_password
# script. But srsly, how ugly is this? could be
# crazy and wrap this as a graphite_user resource with a few
# improvements...
python "set admin password" do
  action :nothing
  cwd "#{base_dir}/webapp/graphite"
  user node['graphite']['user']
  code <<-PYTHON
import os,sys
sys.path.append("#{base_dir}/webapp/graphite")
os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
from django.contrib.auth.models import User

username = "#{node['graphite']['user']}"
password = "#{node['graphite']['password']}"

try:
    u = User.objects.create_user(username, password=password)
    u.save()
except Exception,err:
    print "could not create %s" % username
    print "died with error: %s" % str(err)
  PYTHON
end

runit_service 'graphite-web' do
  cookbook 'graphite'
  default_logger true
end

node.set['grafana']['admin_password']    = Chef::EncryptedDataBagItem.load( node.chef_environment, 'chef_passwords', node['secret'])["graphite_pass"]
node.set['grafana']['graphite_server']   = '127.0.0.1'
node.set['grafana']['graphite_port']     = 8080
node.set['grafana']['graphite_user']     = 'graphite'
node.set['grafana']['graphite_password'] = node['grafana']['admin_password']
node.set['grafana']['user']              = 'grafana'
node.set['grafana']['webserver_listen']  = node['ipaddress']
node.set['grafana']['webserver_port']    = node['roles'].include?('https') ? 443        : 80
node.set['grafana']['webserver_scheme']  = node['roles'].include?('https') ? 'https://' : 'http://'

node.set['grafana']['nginx']['template_cookbook'] = 'TheCheftacularCookbook'

include_recipe "nginx_ssl_setup" if node['roles'].include?('https')
include_recipe "grafana"

htpasswd "/etc/nginx/.htpassword" do
  user     node['TheCheftacularCookbook']['graphite']['grafana_auth_user']
  password node['grafana']['admin_password']
end

htpasswd "/etc/nginx/.htpassword" do
  user     "graphite"
  password node['grafana']['admin_password']
end

execute "ln -sf /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/default"

include_recipe "java"
include_recipe "elasticsearch"

service "nginx" do
  action :restart
end

