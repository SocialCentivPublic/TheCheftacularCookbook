include Chef::DSL::IncludeRecipe
include ::TheCheftacularCookbook::Helper

use_inline_resources if defined?(use_inline_resources)

action :create do
  mount_directory   = new_resource.primary_directory
  cloud_conditional = case node['cheftacular']['preferred_cloud']
                      when 'rackspace'    then 'cat /proc/mounts | grep #{ mount_directory }'
                      when 'digitalocean' then '' #TODO REFACTOR TO BETTER SOLUTION THAT CHECKS NODE STATE
                      end

  rackspacecloud_cbs new_resource.name do
    type new_resource.type
    size new_resource.size
    rackspace_username Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret'])['cloud_auth']['rackspace']['username']
    rackspace_api_key Chef::EncryptedDataBagItem.load( 'default', 'authentication', node['secret'])['cloud_auth']['rackspace']['api_key']
    rackspace_region "dfw"
    retries 1
    action :create_and_attach
  end if node['cheftacular']['preferred_cloud'] == 'rackspace' 

  directory mount_directory do
    user  node['cheftacular']['deploy_user']
    group node['cheftacular']['deploy_user']
    mode  "0755"
    not_if cloud_conditional
  end

  #lazy load mount point
  execute "create_fs" do
    command lazy { "mkfs -t ext3 #{ node[:rackspacecloud][:cbs][:attached_volumes].select{|attachment| attachment[:display_name] == new_resource.name}.first[:device] }" }
    user    "root"
    not_if "cat /proc/mounts | grep #{ mount_directory }"
  end if node['cheftacular']['preferred_cloud'] == 'rackspace'

  mount mount_directory do
    device lazy { node[:rackspacecloud][:cbs][:attached_volumes].select{|attachment| attachment[:display_name] == new_resource.name}.first[:device] }
    fstype "ext3"
    not_if "cat /proc/mounts | grep #{ mount_directory }"
  end if node['cheftacular']['preferred_cloud'] == 'rackspace'

  new_resource.sub_directories.each_pair do |dirpath, dir_hash|
    if dir_hash.has_key?(:not_if)
      directory "#{ mount_directory }/#{ dirpath }" do
        user      dir_hash.has_key?(:user) ? dir_hash[:user] : node['cheftacular']['deploy_user']
        group     dir_hash.has_key?(:group) ? dir_hash[:group] : node['cheftacular']['deploy_user']
        mode      dir_hash.has_key?(:mode) ? dir_hash[:mode] : '700'
        recursive dir_hash.has_key?(:recursive)
        not_if    dir_hash[:not_if]
      end
    elsif dir_hash.has_key?(:only_if)
      directory "#{ mount_directory }/#{ dirpath }" do
        user      dir_hash.has_key?(:user) ? dir_hash[:user] : node['cheftacular']['deploy_user']
        group     dir_hash.has_key?(:group) ? dir_hash[:group] : node['cheftacular']['deploy_user']
        mode      dir_hash.has_key?(:mode) ? dir_hash[:mode] : '700'
        recursive dir_hash.has_key?(:recursive)
        only_if   dir_hash[:only_if]
      end
    else
      directory "#{ mount_directory }/#{ dirpath }" do
        user      dir_hash.has_key?(:user) ? dir_hash[:user] : node['cheftacular']['deploy_user']
        group     dir_hash.has_key?(:group) ? dir_hash[:group] : node['cheftacular']['deploy_user']
        mode      dir_hash.has_key?(:mode) ? dir_hash[:mode] : '700'
        recursive dir_hash.has_key?(:recursive)
      end
    end
  end
end

action :destroy do

end
