#!/usr/bin/env ruby
#
# Postgres Alive Plugin
#
# This plugin attempts to login to postgres with provided credentials.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
#require 'pg'

class CheckPostgres < Sensu::Plugin::Check::CLI

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

  def run
    begin
      auth = "PGPASSWORD=#{ config[:password] }"
      flags = "-h #{ config[:hostname] } -p #{ config[:port] } -d #{ config[:database] } -U #{ config[:user] } -c"
      con = "#{ auth } psql #{ flags }"

      res = `#{ con } 'select version();'`

      if res.empty? || !res.include?('version') || res.include?('could not connect to server')
        critical "Error: Postgres is not running!"
      else
        ok "Server version: #{ res }"
      end
    rescue StandardError => e
      critical "Error message: #{res}\n#{e.error.split("\n").first}"
    end
  end

end
