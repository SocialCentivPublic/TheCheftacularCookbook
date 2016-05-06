
gems = ['net-ping', 'sensu-plugin', 'rest-client', 'ridley', 'spice']

gems << ['bundler', 'rspec', 'spork', 'webmock', 'simplecov'] if node['roles'].include?('sensu_build')

gems << node['TheCheftacularCookbook']['sensu']['sensu_gems'] if node['TheCheftacularCookbook']['sensu'].has_key?('sensu_gems')

if node['setup_sensu_gems'].nil? || (node['TheCheftacularCookbook']['sensu'].has_key?('reinstall_sensu_gems') && node['TheCheftacularCookbook']['sensu']['reinstall_sensu_gems'])
  gems.flatten.each do |spec_gem|
    execute "sudo /opt/sensu/embedded/bin/gem install #{ spec_gem }"
  end
end

if node['roles'].include?('sensu_server')
  execute "sudo /opt/sensu/embedded/bin/gem install chef -v 12.2.1" # TODO chef requires > 2.0.0 after this version (need to update sensu)

  execute "sudo /opt/sensu/embedded/bin/gem install cheftacular"
end

node.set['setup_sensu_gems'] = true
