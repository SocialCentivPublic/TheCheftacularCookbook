
node['loaded_applications'].each do |app_role_name|
  next unless has_repo_hash?(app_role_name)
  next unless repo_hash(app_role_name)['database'] == 'postgresql'

  cron_string = "su - postgres -c \"psql #{ repo_hash['repo_name'] }_#{ node['environment_name'] }" +
    " -c \\\"VACUUM VERBOSE ANALYZE\\\"\" > /root/run_vacuum_analyze_#{ repo_hash['repo_name'] }.log 2&>1"

  cron "vacuum_analyze_#{ repo_hash['repo_name'] }_database" do
    minute  "15"
    hour    "7"
    user    "root"
    command cron_string
  end
end
