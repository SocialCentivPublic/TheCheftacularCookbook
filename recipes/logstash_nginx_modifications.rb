
node.set['nginx']['log_dir_perm'] = '755'

execute "chmod 644 $(find /var/log/nginx -type f)"
