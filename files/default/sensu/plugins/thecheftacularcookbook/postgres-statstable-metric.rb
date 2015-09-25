#!/usr/bin/env ruby
#
# Postgres Stat Table Metrics
# ===
#
# Dependencies
# -----------
# - PSQL `track_counts` enabled
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
#require 'pg'
require 'socket'

class PostgresStatsTableMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :user,
         :description => "Postgres User",
         :short       => '-u USER',
         :long        => '--user USER'

  option :password,
         :description => "Postgres Password",
         :short       => '-p PASS',
         :long        => '--password PASS'

  option :hostname,
         :description => "Hostname to login to",
         :short       => '-h HOST',
         :long        => '--hostname HOST',
         :default     => 'localhost'

  option :port,
         :description => "Database port",
         :short       => '-P PORT',
         :long        => '--port PORT',
         :default     => 5432

  option :db,
         :description => "Database name",
         :short       => '-d DB',
         :long        => '--db DB',
         :default     => 'postgres'

  option :scope,
         :description => "Scope, see http://www.postgresql.org/docs/9.2/static/monitoring-stats.html",
         :short       => '-s SCOPE',
         :long        => '--scope SCOPE',
         :default     => 'user'

  option :scheme,
         :description => "Metric naming scheme, text to prepend to $queue_name.$metric",
         :long        => "--scheme SCHEME",
         :default     => "#{Socket.gethostname}.postgresql"

  def run
    timestamp = Time.now.to_i

    auth = "PGPASSWORD=#{ config[:password] }"
    flags = "-h #{ config[:hostname] } -p #{ config[:port] } -d #{ config[:db] } -U #{ config[:user] } -t -c"
    con = "#{ auth } psql #{ flags }"

    request = [
        "select sum(seq_scan) as seq_scan, sum(seq_tup_read) as seq_tup_read,",
        "sum(idx_scan) as idx_scan, sum(idx_tup_fetch) as idx_tup_fetch,",
        "sum(n_tup_ins) as n_tup_ins, sum(n_tup_upd) as n_tup_upd, sum(n_tup_del) as n_tup_del,",
        "sum(n_tup_hot_upd) as n_tup_hot_upd, sum(n_live_tup) as n_live_tup, sum(n_dead_tup) as n_dead_tup",
        "from pg_stat_user_tables"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    res.split("\n").each do |row|
      next if row.empty?

      data_arr = row.split("|")
    
      output "#{config[:scheme]}.statstable.#{config[:db]}.seq_scan", data_arr[0].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.seq_tup_read", data_arr[1].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.idx_scan", data_arr[2].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.idx_tup_fetch", data_arr[3].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_tup_ins", data_arr[4].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_tup_upd", data_arr[5].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_tup_del", data_arr[6].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_tup_hot_upd", data_arr[7].strip, timestamp 
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_live_tup", data_arr[8].strip, timestamp
      output "#{config[:scheme]}.statstable.#{config[:db]}.n_dead_tup", data_arr[9].strip, timestamp
    end

    ok

  end

end
