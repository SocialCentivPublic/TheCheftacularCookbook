
node['loaded_applications'].each_key do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name).has_key?('application_crons')

  repo_hash(app_role_name)['application_crons'].each_pair do |cron_name, cron_hash|
    cron_hash['rake_command'] ||= "cd CURRENT_PATH && RAILS_ENV=CURRENT_ENVIRONMENT #{ node['unsourced_bundle_command'] } exec rake"

    true_command = case cron_hash['type']
                   when 'rake' then "#{ cron_hash['rake_command'] } #{ cron_hash['command'] }"
                   when 'raw'  then "#{ cron_hash['command'] }"
                   end

    true_command = true_command.gsub('CURRENT_PATH', repo_hash(app_role_name)['current_path']).gsub('CURRENT_ENVIRONMENT', node['environment_name'])

    cron cron_name do
      minute   cron_hash['minute']
      hour     cron_hash['hour']
      user     cron_hash.has_key?('user') ? cron_hash['user'] : node['cheftacular']['deploy_user']
      command  true_command
    end
  end
end
