#!/usr/bin/env ruby
# ===
#
# Check if a url is returning data
#
# We check a local URL and then check the load balancer with a host in order to verify this.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'timeout'
require 'sensu-plugin/check/cli'
require 'net/http'
require 'net/https'

class CheckHTTP < Sensu::Plugin::Check::CLI

  option :base_url,
    :short => '-b BASE_URL',
    :long => '--base-url BASE_URL',
    :description => 'Specify a base url please',
    :default => 'localhost'

  option :use_https,
    :short => '-s USE_HTTPS',
    :long => '--use-https USE_HTTPS',
    :description => 'Should this use HTTPS?',
    :default => '0'

  def run(response=nil)
    Timeout::timeout(5) {
      response = get(config[:base_url])
    }

    if response.nil?
      puts "WARNING! NO RESPONSE IN 5 SECONDS OR SOME OTHER ISSUE FOR #{ config[:base_url] }"; exit 2
    else
      puts "Queried #{ config[:base_url] } and obtained data. All is well."; exit 0
    end
  end

  def get(url, use_header = false)
    schema = config[:use_https].to_i == 1 ? 'https' : 'http'
    uri = URI("#{schema}://#{url}/")
    headers = {}
    headers['HOST'] = config[:base_url] if use_header
    http = Net::HTTP.new(uri.host, uri.port)
    path = uri.path
    http.get(path, headers).body
  end
end
