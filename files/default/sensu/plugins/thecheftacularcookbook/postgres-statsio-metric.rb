#!/usr/bin/env ruby
#
# Postgres StatIO Metrics
# ===
#
# Dependencies
# -----------
# - PSQL `track_io_timing` enabled
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
#require 'pg'
require 'socket'

class PostgresStatsIOMetrics < Sensu::Plugin::Metric::CLI::Graphite

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
        "select sum(heap_blks_read) as heap_blks_read, sum(heap_blks_hit) as heap_blks_hit,",
        "sum(idx_blks_read) as idx_blks_read, sum(idx_blks_hit) as idx_blks_hit,",
        "sum(toast_blks_read) as toast_blks_read, sum(toast_blks_hit) as toast_blks_hit,",
        "sum(tidx_blks_read) as tidx_blks_read, sum(tidx_blks_hit) as tidx_blks_hit",
        "from pg_statio_#{config[:scope]}_tables"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    res.split("\n").each do |row|
      next if row.empty?

      data_arr = row.split("|")

      output "#{config[:scheme]}.statsio.#{config[:db]}.heap_blks_read", data_arr[0].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.heap_blks_hit", data_arr[1].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.idx_blks_read", data_arr[2].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.idx_blks_hit", data_arr[3].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.toast_blks_read", data_arr[4].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.toast_blks_hit", data_arr[5].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.tidx_blks_read", data_arr[6].strip, timestamp
      output "#{config[:scheme]}.statsio.#{config[:db]}.tidx_blks_hit", data_arr[7].strip, timestamp
    end

    ok

  end
end
