
include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  repo_hash = repo_hash(app_role_name)
  
  TheCheftacularCookbook_business_application repo_hash['repo_name'] do
    type      repo_hash['stack']
    role_name app_role_name
  end
end
