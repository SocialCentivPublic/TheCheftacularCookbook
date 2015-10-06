
#when this is set to true, backup gem via chef will drop the backups into this node after sometime around 3:00 am
node.set['receive_long_term_backups'] = true

node.set['main_backup_location']  = '/mnt/backupmaster/backups'

include_recipe "TheCheftacularCookbook::backup_prepare_storage_backups_volume"
include_recipe "TheCheftacularCookbook::backup_all_bags_on_disk"
