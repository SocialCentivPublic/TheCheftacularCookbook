
include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  repo_hash = repo_hash(app_role_name)

  repo_hash['application_services'].each_pair do |task_name, task_hash|
    next unless node['roles'].include?(task_hash['deactivate_on_role'])

    service_name = task_name.gsub('_', '-') if task_hash.has_key?('rewrite_underscore_to_dash')

    TheCheftacularCookbook_business_service service_name do
      type             repo_hash['stack']
      application_name repo_hash['repo_name']
      task             task_hash['command']
      action           :destroy
    end
  end
end
