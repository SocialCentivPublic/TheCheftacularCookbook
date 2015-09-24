#!/usr/bin/env ruby
#
# Postgres Replication Slave Plugin
#
# This plugin attempts to login to postgres with provided credentials.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'date'
#require 'pg'

class PostgresSlaveReplicationStatus < Sensu::Plugin::Check::CLI

  option :user,
         :description => "Postgres User",
         :short => '-u USER',
         :long => '--user USER'

  option :password,
         :description => "Postgres Password",
         :short => '-p PASS',
         :long => '--password PASS'

  option :hostname,
         :description => "Hostname to login to",
         :short => '-h HOST',
         :long => '--hostname HOST'

  option :database,
         :description => "Database schema to connect to",
         :short => '-d DATABASE',
         :long => '--database DATABASE',
         :default => "test"

  option :port,
         :description => "Database port",
         :short => '-P PORT',
         :long => '--port PORT',
         :default => 5432

  option :warn_hour_check,
         description: "timeframe to send warns on. Defaults to 2",
         short: '-w INTEGER',
         long: '--warn-hours INTEGER',
         default: 2

  option :critical_hour_check,
         description: "timeframe to send warns on. Defaults to 2",
         short: '-c INTEGER',
         long: '--critical-hours INTEGER',
         default: 4

  def run
    begin
      auth = "PGPASSWORD=#{ config[:password] }"
      flags = "-h #{ config[:hostname] } -p #{ config[:port] } -d #{ config[:database] } -U #{ config[:user] } -t -c"
      con = "#{ auth } psql #{ flags }"

      res = `#{ con } 'select now() - pg_last_xact_replay_timestamp() AS replication_delay;'`

      if res.empty? || res.include?('could not connect to server')
        critical "Error: Postgres is not running!"
      else
        datetime = DateTime.parse(res.strip)

        if datetime.hour >= config[:warn_hour_check] && datetime.hour <= config[:critical_hour_check]
          warning "Postgres Replication delay is greater than #{ config[:warn_hour_check] } hours"
        elsif datetime.hour > config[:critical_hour_check]
          critical "Postgres Replication delay is greater than #{ config[:critical_hour_check] } hours! Currently #{ datetime.hour }!"
        else
          ok "Postgres Replication delay is less than #{ config[:warn_hour_check] } hours"
        end
      end
    rescue StandardError => e
      critical "Error message: #{res}\n#{e.error.split("\n").first}"
    end
  end
end
