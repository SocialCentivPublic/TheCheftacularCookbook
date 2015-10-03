include Chef::DSL::IncludeRecipe
include ::TheCheftacularCookbook::Helper
include ::TheCheftacularCookbook::ApplicationDefault

use_inline_resources if defined?(use_inline_resources)

action :create do
  app_hash = {}

  #TODO examine use of evals here to DRY this up?
  app_hash = initialize_rails_application     if new_resource.type == 'ruby_on_rails'
  app_hash = initialize_lamp_application      if new_resource.type == 'lamp'
  app_hash = initialize_nodejs_application    if new_resource.type == 'nodejs'
  app_hash = initialize_wordpress_application if new_resource.type == 'wordpress'

  install_inline_packages if repo_hash(new_resource.role_name).has_key?('custom_packages')

  post_application_linking(new_resource.type, app_hash)
end

action :destroy do

end

def initialize_lamp_application
  app_hash = return_application_defaults_as_hash(new_resource.name, new_resource.type, new_resource.role_name)

  include_recipe "nginx" if node['lamp_stack_to_install'].include?('nginx')

  if node['lamp_stack_to_install'].include?('mysql')
    include_recipe "mysql::client"

    include_recipe "mysql::server"
  end

  if repo_hash(new_resource.role_name)['stack'] == 'wordpress'
    #these must occur AFTER installing mysql
    node.set['wordpress']['php_options'] = { 'upload_max_filesize' => '64M', 'post_max_size' => '55M' }
    node.set['wordpress']['dir']         = "#{ app_hash['path'] }/wordpress"

    include_recipe "wordpress"
  end

  return true if node['skip_deploys'] == true

  application new_resource.name do
    path              app_hash['path']
    owner             node.has_key?['special_application_owner'] ? node['special_application_owner'] : node['cheftacular']['deploy_user']
    group             'www-data'
    environment       node['ruby-env']
    revision          app_hash["repo_branch"]
    repository        app_hash['repo_computed_url']
    shallow_clone     false
    deploy_key        app_hash['key_data']['git_private_key']
    rollback_on_error node['TheCheftacularCookbook']['deploys']['rollback_on_error'] #allow for debugging of code placed in directory if false.
  end

  if repo_hash(new_resource.role_name)['sub_stack'] == 'sencha'
    operations_directory = repo_hash(new_resource.role_name)['operations_directory']
  
    directory "#{ app_hash["current_path"] }/#{ operations_directory }" do
      user  node['cheftacular']['deploy_user']
      group "www-data"
      mode  "0775"
      recursive true
    end

    execute "/opt/sencha/Sencha/Cmd/#{ node['sencha_cmd']['version'] }/sencha app build production" do
      cwd app_hash["current_path"]
    
      not_if "/usr/bin/test -e #{ app_hash['current_path'] }/#{ operations_directory }/index.html && echo \"true\"" #test if operations directory is already built
    end 
  end

  template "/etc/nginx/sites-available/#{ new_resource.name }" do
    source 'directory_sites_available.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    variables(
      name:           app_hash["server_url"],
      base_directory: "#{ app_hash['current_path'] }",#/#{ h['operations_directory'] }",
      log_dir:        node['nginx']['log_dir']
    )
    if ::File.exists?("#{node['nginx']['dir']}/sites-enabled/#{ new_resource.name }")
      notifies :reload, 'service[nginx]'
    end
  end if node['lamp_stack_to_install'].include?('nginx')

  app_hash
end

def initialize_nodejs_application
  app_hash = return_application_defaults_as_hash(new_resource.name, new_resource.type, new_resource.role_name)

  if node['cheftacular']['repositories'][new_resource.role_name]['sub_stack'] == 'meteor'
    execute "install_meteor" do
      command "curl https://install.meteor.com/ | sh"
      not_if  "which meteor"
    end

    execute "chown #{ node['cheftacular']['deploy_user'] }:#{ node['cheftacular']['deploy_user'] } -R /home/#{ node['cheftacular']['deploy_user'] }/.meteor"

    include_recipe 'mongodb'
  end

  include_recipe 'nodejs'

  nodejs_npm 'http-server' do
    name 'http-server'
  end

  include_recipe "nginx"

  execute_command = 'http-server ./app'
  env_vars        = []

  template "/etc/nginx/sites-available/default" do
    source 'general_sites_available.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    variables(
      name:       new_resource.name,
      base_name:  new_resource.name,
      log_dir:    node['nginx']['log_dir'],
      path:       app_hash['current_path'],
      target_url: "http://localhost:8080"
    )
    if ::File.exists?("#{node['nginx']['dir']}/sites-enabled/default")
      notifies :reload, 'service[nginx]'
    end
  end

  application new_resource.name do
    path              app_hash['path']
    owner             node['cheftacular']['deploy_user']
    group             'www-data'
    environment       node['ruby-env']
    revision          app_hash["repo_branch"]
    repository        app_hash['repo_computed_url']
    shallow_clone     false
    deploy_key        app_hash['key_data']['git_private_key']
    rollback_on_error node['TheCheftacularCookbook']['deploys']['rollback_on_error'] #allow for debugging of code placed in directory if false.
  end

  if node['cheftacular']['repositories'][new_resource.role_name]['sub_stack'] =~ /meteor/
    ops_dir = "#{ app_hash['current_path'] }/#{ repo_hash(new_resource.role_name)['operations_directory'] }/#{ node.chef_environment }"

    directory ops_dir do
      user  node['cheftacular']['deploy_user']
      group "www-data"
      mode  "0775"
      recursive true
    end

    if node['cheftacular']['repositories'][new_resource.role_name]['sub_stack'] == 'meteor'
      execute 'build_operations_file_for_meteor' do
        cwd     app_hash["current_path"]
        command "/usr/local/bin/meteor build --directory #{ ops_dir } && cd #{ ops_dir }/bundle/programs/server && npm install"
        not_if  { ::File.exists?("#{ ops_dir }/bundle/main.js") }
      end

      root_url = 'localhost'

      node['addresses'][node.chef_environment].each do |server_hash|
        next if server_hash['name'] != node['hostname'].gsub("#{ node.chef_environment }-",'')

        root_url = server_hash['dn']
      end

      execute_command = "node #{ ops_dir }/bundle/main.js"
      env_vars        = ['PORT=8080', 'MONGO_URL=mongodb://localhost:27017/mongodb', "ROOT_URL=http://#{ root_url }"]
    end
  end

  template "/etc/init/#{ new_resource.name }-server.conf" do
    source 'node_service.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    variables(
      user:           node['cheftacular']['deploy_user'],
      file_name:      "#{ new_resource.name }.conf",
      command:        execute_command,
      app_loc:        app_hash["current_path"],
      environment:    node.chef_environment,
      logger:         new_resource.name,
      env_vars:       env_vars
    )
    if ::File.exists?("/etc/init/#{ new_resource.name }.conf")
      notifies :restart, "service[#{ new_resource.name }]"
    end
  end

  service "#{ new_resource.name }-server" do
    provider Chef::Provider::Service::Upstart
    supports enable: true, start: true, status: true, restart: true
    action [:start, :enable]
  end

  if ::File.exists?("/etc/init/#{ new_resource.name }-server.conf")
    service "#{ new_resource.name }-server" do
      provider Chef::Provider::Service::Upstart
      action :restart
    end
  end

  app_hash
end

def initialize_rails_application
  app_hash = return_application_defaults_as_hash(new_resource.name, new_resource.type, new_resource.role_name)

  include_recipe "postgresql::client"

  return true if node['skip_deploys'] == true

  application new_resource.name do
    path              app_hash['path']
    owner             node['cheftacular']['deploy_user']
    group             'www-data'
    environment       node['ruby-env']
    revision          app_hash["repo_branch"]
    repository        app_hash['repo_computed_url']
    shallow_clone     false
    symlinks          app_hash['syms']
    deploy_key        app_hash['key_data']['git_private_key']
    rollback_on_error true #allow for debugging of code placed in directory if false.

    rails do
      bundle_command                  node['bundle_command']
      environment_name                node['environment_name']
      bundler                         true
      bundle_options                  '--jobs 2' if app_hash['run_web']
      bundler_with_groups             ['test'] if app_hash['is_sensu_build']
      rvm_path                        node['rvm']['rvm_home']
      precompile_assets               true if app_hash['run_web']
      remove_assets_before_precompile true if app_hash['run_web']
      symlink_logs                    true

      database do
        adapter  "postgresql"
        host     app_hash['db_master_node']
        port     5432
        pool     20
        database "#{ app_hash['db_name'] }_#{ app_hash['db_environment'] }" #for whatever reason, you cant pass in node.chef_environment directly
        username app_hash['db_user']
        password app_hash['pg_pass']
        params   app_hash['db_attrs']
      end
    end

    if app_hash['run_web']

      nginx do
        custom_server_configs app_hash['custom_nginx_configs']

        server_aliases [ app_hash["server_url"], app_hash["server_url_aliases"] ].flatten.compact
      end

      puma do
        app_path         app_hash["path"]
        on_worker_boot   app_hash["pg_connection"] ? app_hash['puma_pg_worker_boot'] : nil
        upstart          true
      end
    end
  end

  #activate if cleanup becomes a problem
  cron "cleanup_#{ new_resource.name }_#{ node['environment_name'] }.log" do
    minute  "0"
    hour    "0"
    day     "1"
    user    node['cheftacular']['deploy_user']
    command "tail -5000 #{ app_hash['current_path'] }/log/#{ node['environment_name'] }.log > #{ app_hash['current_path'] }/log/#{ node['environment_name'] }.log"
  end if node[new_resource.name]['run_log_cleanup']

  execute 'restart_puma_rails_apps' do
    command "#{ app_hash['shared_path'] }/puma/puma_start.sh"
    user    "root"
    only_if { ::File.exists?("#{ app_hash['shared_path'] }/puma/puma_restart.sh") }
  end

  app_hash
end

def initialize_wordpress_application
  node.set['mysql']['server_root_password'] = Chef::EncryptedDataBagItem.load(node.chef_environment,"chef_passwords", node['secret'])['mysql_root_pass']
  node.set['wordpress']['db']['name']       = repo_hash(new_resource.role_name)['application_database_user']
  node.set['wordpress']['db']['user']       = node['wordpress']['db']['name']
  node.set['wordpress']['db']['pass']       = Chef::EncryptedDataBagItem.load(node.chef_environment,"chef_passwords", node['secret'])['mysql_app_pass']
  node.set['wordpress']['db']['host']       = 'localhost'
  node.set['wordpress']['allow_multisite']  = false

  app_hash = initialize_lamp_applicationapp_hash = return_application_defaults_as_hash(new_resource.name, new_resource.type, new_resource.role_name)

  execute 'rm /var/www/wordpress/wp-content' do
    command "rm -R #{ node['wordpress']['dir'] }/wp-content"
    only_if { ::File.directory?("#{ node['wordpress']['dir'] }/wp-content")}
  end

  execute 'link wordpress wp-content dir' do
    command "ln -fs #{ app_hash['current_path'] }/wp-content #{ node['wordpress']['dir'] }"
  end

  execute 'mkdir-uploads' do
    command "mkdir -p #{ app_hash['shared_path'] }/uploads"
  end

  execute 'link uploads to wordpress' do
    command "ln -fs /shared/uploads #{ app_hash['current_path'] }/wp-content"
  end

  execute "chown -R www-data:www-data #{ app_hash['path'] }"

  #Fixing issue with redeploys not being able to write git files
  execute "chmod -R 775 #{ app_hash['current_path'] }/wp-content"

  app_hash
end

def install_inline_packages
  repo_hash(new_resource.role_name)['custom_packages'].each do |package_name|
    package package_name
  end
end

def post_application_linking mode, app_hash={}
  execute "ln -sf #{ node['nginx']['dir']}/sites-available/#{ app_hash['name'] } #{ node['nginx']['dir']}/sites-enabled/default" do
    only_if "/usr/bin/test -d /etc/nginx && echo \"true\""
  end if node['roles'].include?('web')

  directory "#{ app_hash['shared_path'] }/public" do
    owner node['cheftacular']['deploy_user']
    group "www-data"
    mode  "755"
  end if mode =~ /ruby_on_rails/

  #this doesn't get automatically created if you dont run a rails server, make sure it exists
  directory "#{ app_hash['current_path'] }/tmp" do
    owner node['cheftacular']['deploy_user']
    group "www-data"
    mode  "755"
  end if mode =~ /ruby_on_rails/

  #needed for dj workers
  directory "#{ app_hash['shared_path'] }/pids" do
    owner node['cheftacular']['deploy_user']
    group "www-data"
    mode  "755"
  end if mode =~ /ruby_on_rails/

  execute "rm -rf #{ app_hash["current_path"] }/public/public" do
    only_if "/usr/bin/test -d #{ app_hash["current_path"] }/public/public && echo \"true\""
  end if mode =~ /ruby_on_rails/

  execute "rm #{ app_hash["current_path"] }/public/public" do
    only_if "/usr/bin/test -e #{ app_hash["current_path"] }/public/public && echo \"true\""
  end if mode =~ /ruby_on_rails/

  execute "cp -R * #{ app_hash['shared_path'] }/public && rm -rf #{ app_hash["current_path"] }/public" do
    cwd    "#{ app_hash["current_path"] }/public"
    not_if "/usr/bin/test -L #{ app_hash['current_path'] }/public && echo \"true\"" #test if symlink is already made
  end if mode =~ /ruby_on_rails/

  execute "ln -sf #{ app_hash["shared_path"] }/public #{ app_hash["current_path"] }" do
    not_if "/usr/bin/test -L #{ app_hash['current_path'] }/public && echo \"true\"" #test if symlink is already made
  end if mode =~ /ruby_on_rails/

  execute "ln -sf #{ app_hash["shared_path"] }/pids #{ app_hash["current_path"] }/tmp" do
    not_if "/usr/bin/test -L #{ app_hash['current_path'] }/tmp/pids && echo \"true\"" #test if symlink is already made
  end if mode =~ /ruby_on_rails/

  execute "chown -R #{ node['cheftacular']['deploy_user'] }:www-data #{ app_hash['path'] }" unless mode =~ /wordpress/
end
