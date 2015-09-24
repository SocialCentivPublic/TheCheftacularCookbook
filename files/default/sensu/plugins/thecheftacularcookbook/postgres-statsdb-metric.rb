#!/usr/bin/env ruby
#
# Postgres Stat DB Metrics
# ===
#
# Dependencies
# -----------
# - PSQL `track_counts` `track_io_timing` for some metrics enabled
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
#require 'pg'
require 'socket'

class PostgresStatsDBMetrics < Sensu::Plugin::Metric::CLI::Graphite

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
        "select xact_commit, xact_rollback,",
        "blks_read, blks_hit,",
        "tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted",
        "from pg_stat_database where datname='#{config[:db]}'"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    res.split("\n").each do |row|
      next if row.empty?

      data_arr = row.split("|")

      output "#{config[:scheme]}.statsdb.#{config[:db]}.xact_commit", data_arr[0].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.xact_rollback", data_arr[1].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.blks_read", data_arr[2].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.blks_hit", data_arr[3].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.tup_returned", data_arr[4].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.tup_fetched", data_arr[5].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.tup_inserted", data_arr[6].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.tup_updated", data_arr[7].strip, timestamp
      output "#{config[:scheme]}.statsdb.#{config[:db]}.tup_deleted", data_arr[8].strip, timestamp
    end

    ok

  end

end
