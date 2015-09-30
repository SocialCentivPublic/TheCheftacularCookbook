
include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  repo_hash = repo_hash(app_role_name)

  repo_hash['application_services'].each_pair do |task_name, task_hash|
    next unless node['roles'].include?(task_hash['run_on_role'])

    env_vars = []

    env_vars << parse_queues_into_env_var_from_service(task_hash) if task_hash['queues']

    service_name = task_name.gsub('_', '-') if task_hash.has_key?('rewrite_underscore_to_dash')

    TheCheftacularCookbook_business_service service_name do
      type                    repo_hash['stack']
      application_name        repo_hash['repo_name']
      task                    task_hash['command']
      environment_vars        env_vars.flatten.join(' ')
      application_log_cleanup task_hash.has_key('application_log_cleanup')
      delayedjob_log_cleanup  task_hash.has_key('delayedjob_log_cleanup')
      syslog_cleanup          task_hash.has_key('syslog_cleanup')
    end
  end
end
