
#when this is set to true, backup gem via chef will drop the backups into this node after sometime around 3:00 am
node.set['receive_backups'] = true

node.set['main_backup_location']  = '/mnt/postgresbackups/backups'

include_recipe "TheCheftacularCookbook::db_prepare_storage_backups_volume"
