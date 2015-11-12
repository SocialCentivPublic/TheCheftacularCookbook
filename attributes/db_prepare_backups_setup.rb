default['main_backup_location']          = '/mnt/postgresbackups/backups'
default['backup']['config_path']         = "#{ node['main_backup_location'] }/backup_gem"
default['backup']['model_path']          = "#{ node['backup']['config_path'] }/models"
default['backupmaster_storage_location'] = '/mnt/backupmaster/backups'

#TODO THECHEFTACULARCOOKBOOKIFY
default['short_term_backup_count'] = 5
default['long_term_backup_count']  = 93
default['local_db_backup_count']   = 4


default['backup_cron']['minute']            = "50"
default['backup_cron']['hour']              = "7"
default['restart_pg_replication']['minute'] = "0"
default['restart_pg_replication']['hour']   = "9"
