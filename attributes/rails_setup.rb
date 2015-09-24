#We really need to rearchitect the puma gem...
default['puma'][:version] = "2.8.2"
default['puma'][:bundler_version] = "1.6.1"
default['puma'][:rubygems_location] = "#{ node['rvm_home'] }/rubies/#{ node['default_ruby'] }/bin/gem"
override['nginx']['pid'] = '/run/nginx.pid'
