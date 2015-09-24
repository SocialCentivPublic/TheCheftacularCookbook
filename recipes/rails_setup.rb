
include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  business_application repo_hash(app_role_name)['repo_name'] do
    type      repo_hash(app_role_name)['stack']
    role_name app_role_name
  end
end
