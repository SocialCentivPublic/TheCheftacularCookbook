#!/usr/bin/env ruby
#
# Postgres Stat BGWriter Metrics
# ===
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

  option :scheme,
         :description => "Metric naming scheme, text to prepend to $queue_name.$metric",
         :long        => "--scheme SCHEME",
         :default     => "#{Socket.gethostname}.postgresql"

  def run
    timestamp = Time.now.to_i

    auth = "PGPASSWORD=#{ config[:password] }"
    flags = "-h #{ config[:hostname] } -p #{ config[:port] } -d postgres -U #{ config[:user] } -t -c"
    con = "#{ auth } psql #{ flags }"

    request = [        
        "select checkpoints_timed, checkpoints_req,",
        "buffers_checkpoint, buffers_clean,",
        "maxwritten_clean, buffers_backend,",
        "buffers_alloc",
        "from pg_stat_bgwriter"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    res.split("\n").each do |row|
      next if row.empty?

      data_arr = row.split("|")

      output "#{config[:scheme]}.bgwriter.checkpoints_timed", data_arr[0].strip, timestamp
      output "#{config[:scheme]}.bgwriter.checkpoints_req", data_arr[1].strip, timestamp
      output "#{config[:scheme]}.bgwriter.buffers_checkpoint", data_arr[2].strip, timestamp
      output "#{config[:scheme]}.bgwriter.buffers_clean", data_arr[3].strip, timestamp
      output "#{config[:scheme]}.bgwriter.maxwritten_clean", data_arr[4].strip, timestamp
      output "#{config[:scheme]}.bgwriter.buffers_backend", data_arr[5].strip, timestamp
      output "#{config[:scheme]}.bgwriter.buffers_alloc", data_arr[6].strip, timestamp
    end

    ok

  end

end
