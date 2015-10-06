include Chef::DSL::IncludeRecipe
include ::TheCheftacularCookbook::Helper

use_inline_resources if defined?(use_inline_resources)

action :create do
  initialize_rails_service if new_resource.type == 'ruby_on_rails'
end

action :destroy do
  service application_service_name do
    provider Chef::Provider::Service::Upstart
    action :stop

    only_if { ::File.exists?("/etc/init/#{ application_service_name }.conf") }
  end

  execute "rm /etc/init/#{ application_service_name }.conf" do
    only_if { ::File.exists?("/etc/init/#{ application_service_name }.conf") }
  end
end

protected

def initialize_rails_service
  template "/etc/init/#{ application_service_name }.conf" do
    source 'ruby_service.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    variables(
      user:           node['cheftacular']['deploy_user'],
      file_name:      "#{ application_service_name }.conf",
      command:        new_resource.task,
      app_loc:        node[new_resource.application_name]["current_path"],
      bundle_command: node['unsourced_bundle_command'],
      environment:    node['environment_name'],
      logger:         new_resource.name,
      env_vars:       new_resource.environment_vars
    )
    if ::File.exists?("/etc/init/#{ application_service_name }.conf")
      notifies :restart, "service[#{ application_service_name }]"
    end
  end

  service application_service_name do
    provider Chef::Provider::Service::Upstart
    supports enable: true, start: true, status: true, restart: true
    action [:start, :enable]
  end

  service application_service_name do
    provider Chef::Provider::Service::Upstart
    action :stop
  end

  service application_service_name do
    provider Chef::Provider::Service::Upstart
    action :start
  end

  cron "cleanup_#{ application_service_name.gsub('-','_') }.log" do
    minute  "0"
    hour    "0"
    user    node['cheftacular']['deploy_user']
    command "tail -5000 #{ node[new_resource.application_name]["current_path"] }/log/#{ node['environment_name'] }.log > #{ node[new_resource.application_name]["current_path"] }/log/#{ node['environment_name'] }.log"
  end if new_resource.application_log_cleanup

  cron "cleanup_#{ new_resource.name }_delayed_job_logs" do
    minute  "0"
    hour    "0"
    user    node['cheftacular']['deploy_user']
    command "tail -5000 #{ node[new_resource.application_name]["current_path"]}/log/delayed_job.log > #{ node[new_resource.application_name]["current_path"] }/log/delayed_job.log"
  end if new_resource.delayedjob_log_cleanup

  cron "cleanup_syslog" do
    minute  "0"
    hour    "0"
    user    "root"
    command "tail -5000 /var/log/syslog > /var/log/syslog"
  end if new_resource.syslog_cleanup
end

def application_service_name
  "#{ new_resource.application_name }-#{ new_resource.name }"
end
