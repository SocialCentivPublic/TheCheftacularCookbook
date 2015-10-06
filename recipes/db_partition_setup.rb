
if node['roles'].include?('sensu_build_db')
  check_file = "/home/#{ node['cheftacular']['deploy_user'] }/db_expansion_genfile.sh"

  execute "mkdir -p /mnt/postgresqldata" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "mkdir -p /mnt/postgresqldata/main" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "chmod -R 0700 /mnt/postgresqldata/main" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end
else
  execute "mkfs -t ext3 /dev/xvdc" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "mkdir -p /mnt/postgresqldata" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "sh -c 'echo \"/dev/xvdc       /mnt/postgresqldata ext3 defaults,noatime,nofail             0       0\" | sudo tee -a /etc/fstab'" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "mount -a" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "mkdir -p /mnt/postgresqldata/main" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "pkill postgres" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end

  execute "chmod -R 0700 /mnt/postgresqldata/main" do
    user    "root"
    not_if  { ::File.exists?(check_file) }
  end
end

execute "touch /home/deploy/db_expansion_genfile.sh" do
  not_if  { ::File.exists?(check_file) }
end

execute "echo \"echo setup\" >> /home/deploy/db_expansion_genfile.sh" do
  not_if  { ::File.exists?(check_file) }
end

execute "chmod 754 /home/deploy/db_expansion_genfile.sh" do
  not_if  { ::File.exists?(check_file) }
end