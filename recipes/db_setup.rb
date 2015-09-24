
include_recipe "TheCheftacularCookbook"

include_recipe "TheCheftacularCookbook::db_volume_setup"

include_recipe "TheCheftacularCookbook::db_log_dir_setup"

::Chef::Recipe.send(:include, Opscode::PostgresqlHelpers) #defines the binaryround method

node.set['postgresql']['version'] = "9.3"
node.set['postgresql']['config']['listen_addresses'] = '*' #we're securing inbound via shorewall, can allow everything
node.set['postgresql']['pg_hba'] = [
  { type: 'host',  db: 'all',         user: 'all',      addr: '0.0.0.0/0', method: 'md5'},
  { type: 'local', db: 'all',         user: 'postgres', addr: nil,         method: 'ident'},
  { type: 'local', db: 'all',         user: 'all',      addr: nil,         method: 'ident'},
  { type: 'host',  db: 'all',         user: 'all',      addr: '::1/128',   method: 'md5'},
  { type: 'host',  db: 'replication', user: 'all',      addr: '0.0.0.0/0', method: 'trust'} #this is actually not a security risk
]
node.set['postgresql']['db_type'] = 'web'
#Modifying the cookbook's data directory does change the config file but the process will still try and run at the old location
node.set['postgresql']['config']['data_directory']       = "/mnt/postgresqldata/main"
node.set['postgresql']['config']['shared_buffers']       = node.chef_environment == 'production' ? "1GB" : "512MB"
node.set['postgresql']['config']['work_mem']             = "128MB"
node.set['postgresql']['config']['maintenance_work_mem'] = "1GB"
node.set['postgresql']['config']['checkpoint_segments']  = 144
node.set['postgresql']['config']['max_connections']      = node.chef_environment == 'production' ? 400 : 250

memory = ((node['memory']['total'].split("kB")[0].to_i / 1024) * 2.0) / 4.0

node.set['postgresql']['config']['effective_cache_size'] = binaryround(memory*1024.0*1024.0)

include_recipe "postgresql::server"

include_recipe "postgresql::config_pgtune"

node.set['postgresql']['contrib']['extensions'] = [
  "pageinspect",
  "pg_buffercache",
  "pg_freespacemap",
  "pgrowlocks",
  "pg_stat_statements",
  "pgstattuple",
  "plpgsql"#,
  #"hstore"
]

include_recipe "postgresql::contrib"

include_recipe "TheCheftacularCookbook::db_sshkey_generation"

include_recipe "TheCheftacularCookbook::db_sync_keys"
