
execute "create_fs" do
  command "mkfs -t ext3 /dev/xvde1"
  user    "root"
  not_if  'df -aTh | grep /dev/xvde1'
  only_if 'sudo fdisk -l | grep /dev/xvde1' #we can't mount what does not exist
end

directory "/mnt/data" do
  user  node['cheftacular']['deploy_user']
  group "www-data"
  mode  "0755"
end

execute "update_fstab" do
  command "echo \"/dev/xvde1      /mnt/data       ext3    defaults,noatime,nofail             0       0\" | sudo tee -a /etc/fstab"
  user    "root"
  not_if  'df -aTh | grep /dev/xvde1'
  only_if 'sudo fdisk -l | grep /dev/xvde1' #we can't mount what does not exist
end

execute "mount_all_fs" do
  command "sudo mount -a"
end
