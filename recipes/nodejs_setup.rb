
include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  TheCheftacularCookbook_business_application node['cheftacular']['repositories'][app_role_name]['repo_name'] do
    type      'nodejs'
    role_name app_role_name
  end if node['cheftacular']['repositories'][app_role_name]['stack'] == 'nodejs'
end
