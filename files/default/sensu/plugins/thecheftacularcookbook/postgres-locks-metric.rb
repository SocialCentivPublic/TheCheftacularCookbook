#!/usr/bin/env ruby
#
# Postgres Locks Metrics
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

    locks_per_type = Hash.new(0)

    auth = "PGPASSWORD=#{ config[:password] }"
    flags = "-h #{ config[:hostname] } -p #{ config[:port] } -d #{ config[:db] } -U #{ config[:user] } -t -c"
    con = "#{ auth } psql #{ flags }"

    request = [
        "SELECT mode, count(mode) FROM pg_locks",
        "where database = (select oid from pg_database where datname = '#{config[:db]}')",
        "group by mode"
    ]

    res = `#{ con } "#{ request.join(' ') };"`

    res.split("\n").each do |row|
      next if row.empty?
      
      lock_name = row.split("|").first.strip.downcase.to_sym
      locks_per_type[lock_name] += 1
    end

    locks_per_type.each do |lock_type, count|
      output "#{config[:scheme]}.locks.#{config[:db]}.#{lock_type}", count, timestamp
    end

    ok

  end
end
