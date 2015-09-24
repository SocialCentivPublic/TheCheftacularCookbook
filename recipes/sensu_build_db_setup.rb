
include_recipe 'TheCheftacularCookbook'

include_recipe "TheCheftacularCookbook::db_normal_pg_logging"
include_recipe "TheCheftacularCookbook::db_setup"
include_recipe "TheCheftacularCookbook::db_primary_setup"

#TODO setup other db types like mongodb
node['TheCheftacularCookbook']['sensu_build']['repository_role_names'].each_pair do |app_role_name, settings_hash|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'
  next unless repo_hash(app_role_name)['stack']    == 'rails'

  settings_hash['branches_to_test'].each do |branch|
    base_command = "cd #{ get_current_path(app_role_name,"-#{ branch }") } && RAILS_ENV=#{ node['environment_name'] } #{ node['unsourced_bundle_command'] }"

    execute "#{ base_command } exec rake db:drop"

    execute "#{ base_command } exec rake db:create"

    node.set[repo_hash(app_role_name)['repo_name']]['setup_test_database'] = true

    sleep 5

    postgres_test_db_setup_command = node['cheftacular']['repositories'][app_role_name].has_key?('test_database_setup_command') ? node['cheftacular']['repositories'][app_role_name]['test_database_setup_command'] : 'rake db:test:prepare'

    execute "#{ base_command } exec #{ postgres_test_db_setup_command }"
  end
end
