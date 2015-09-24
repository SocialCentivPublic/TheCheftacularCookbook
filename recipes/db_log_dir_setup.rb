
execute "mkdir -p /mnt/data/postgresql_logs/postgresql" do
  not_if "/usr/bin/test -d /mnt/data/postgresql_logs/postgresql && echo \"true\""
end

directory "/mnt/postgresqldata/backups" do
  user      node['cheftacular']['deploy_user']
  group     node['cheftacular']['deploy_user']
  mode      "777"
  recursive true
end

execute "chgrp #{ node['cheftacular']['deploy_user'] } /mnt/postgresqldata/backups"

execute "chmod g+s /mnt/postgresqldata/backups"

execute "cp * /mnt/data/postgresql_logs/postgresql && rm -rf /var/log/postgresql" do
  cwd    "/var/log/postgresql"

  only_if "/usr/bin/test -d /var/log/postgresql && echo \"true\"" #dont need to do this if the log dir doesnt exist
  not_if "/usr/bin/test -L /var/log/postgresql && echo \"true\"" #dont need to do this if its already symlinked
end

execute "ln -sf /mnt/data/postgresql_logs/postgresql /var/log" do
  not_if "/usr/bin/test -L /var/log/postgresql && echo \"true\"" #test if symlink is already made
end
