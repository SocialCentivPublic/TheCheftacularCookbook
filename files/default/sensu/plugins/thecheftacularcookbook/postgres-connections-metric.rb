#!/usr/bin/env ruby
#
# Postgres Connection Metrics
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
        "select count(*), waiting from pg_stat_activity",
        "where datname = '#{config[:db]}' group by waiting"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    metrics = {
        :active  => 0,
        :waiting => 0
    }
    res.split("\n").each do |row|
      next if row.empty?
      
      metrics[:waiting] = row.split("|").first.strip if row.split("|").last.strip == 'f'
      metrics[:active] = row.split("|").first.strip if row.split("|").last.strip == 't'
    end

    metrics.each do |metric, value|
      output "#{config[:scheme]}.connections.#{config[:db]}.#{metric}", value, timestamp
    end

    ok
  end
end
