
#TODO custom load depending on node['lamp_stack_to_install']

include_recipe "TheCheftacularCookbook"

node['loaded_applications'].each_key do |app_role_name|
  TheCheftacularCookbook_business_application node['cheftacular']['repositories'][app_role_name]['repo_name'] do
    type      'lamp'
    role_name app_role_name
  end if node['cheftacular']['repositories'][app_role_name]['stack'] == 'lamp'
end

include_recipe "TheCheftacularCookbook::restart_services"
