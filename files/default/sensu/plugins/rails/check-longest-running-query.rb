#!/usr/bin/env ruby
#  encoding: UTF-8
#  check-longest-running-query
#
#  DESCRIPTION:
#    This plugin attempts to query a ruby on rails log file and return the results of the run to the handler.
#
#  OUTPUT:
#    plain text
#
#  PLATFORMS:
#    Linux
#
#  DEPENDENCIES:
#    gem: sensu-plugin
#
#  USAGE:
#    Recommended usage:
#      /opt/sensu/embedded/bin/ruby /etc/sensu/plugins/check-longest-running-query.rb -f /path/to/codebase/log/file
#
#  LICENSE:
#    Louis Alridge louis@socialcentiv.com (loualrid@gmail.com)
#    Released under the same terms as Sensu (the MIT license); see LICENSE
#    for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'socket'

#
# LongestRunningQueryMetric
#
class CheckLongestRunningQuery < Sensu::Plugin::Check::CLI
  option :logfile,
         description: 'Log file to check against',
         short: '-f LOGFILE',
         long: '--file LOGFILE'

  option :logfile_lines,
         description: 'Specify how many log file lines to examine. Defaults to 5000',
         short: '-n LINES',
         long: '--number LINES',
         default: 5000

  option :query_time_to_report,
         description: 'Specify the shortest time query you want to alert on. Defaults to 5000',
         short: '-q TIME_IN_MILLISECONDS',
         long: '--query-time TIME_IN_MILLISECONDS',
         default: 5000


  option :scheme,
         :description => "Metric naming scheme, text to prepend to $queue_name.$metric",
         :long        => "--scheme SCHEME",
         :default     => "#{Socket.gethostname}.queries"


  #https://github.com/jrochkind/scrub_rb
  #https://github.com/jrochkind/scrub_rb/blob/master/lib/scrub_rb.rb
  #This method is defined in the ruby 2.2+ standard Lib
  def scrub(str, replacement=nil, &block)
    return str if str.nil?

    if replacement.nil? && ! block_given?
      replacement =
         # UTF-8 for unicode replacement char \uFFFD, encode in
         # encoding of input string, using '?' as a fallback where
         # it can't be (which should be non-unicode encodings)
         "\xEF\xBF\xBD".force_encoding("UTF-8").encode( str.encoding,
                                                  :undef => :replace,
                                                  :replace => '?' )  
    end

    result          = "".force_encoding("BINARY")
    bad_chars       = "".force_encoding("BINARY")
    bad_char_flag   = false # weirdly, optimization to use flag

    str.chars.each do |c|
      if c.valid_encoding?
        if bad_char_flag
          scrub_replace(result, bad_chars, replacement, block)
          bad_char_flag = false
        end
        result << c
      else
        bad_char_flag = true
        bad_chars << c
      end
    end
    if bad_char_flag
      scrub_replace(result, bad_chars, replacement, block)
    end

    result.force_encoding(str.encoding)

    return result
  end

  def scrub_replace(result, bad_chars, replacement, block)
    if block
      r = block.call(bad_chars)
    else
      r = replacement
    end

    if r.respond_to?(:to_str)
      r = r.to_str
    else
      raise TypeError, "no implicit conversion of #{r.class} into String"
    end

    unless r.valid_encoding?
      raise ArgumentError,  "replacement must be valid byte sequence '#{replacement}'"
    end

    result << r
    bad_chars.clear
  end

  def initialize_file_cache location
    File.open(location, 'w+') { |f| f.write('') }
  end

  def write_file_cache_message(location, message)
    File.open(location, 'w+') { |f| f.write(message) }
  end

  def run
    file_cache_location = '/var/log/sensu/check-longest-running-query'

    timestamp = Time.now.to_i

    queries, full_query_lines = [],{}

    if File.exist?(config[:logfile])
      parsed_log_data = scrub(`tail -#{ config[:logfile_lines].to_i } #{ config[:logfile] }`.to_s)

      parsed_log_data.scan(/^(.*\([\d]+\.\dms\).*)$/).flatten.each do |query|
        query_time = query.scan(/\(([\d]+\.\d)ms\)/).flatten[0].to_f

        next if query_time < config[:query_time_to_report].to_f

        queries << query_time

        full_query_lines[query_time] = query.gsub("",'').gsub(/\[0m|\[1m|\[32m|\[35m|\[36m/,'')
      end

      if queries.empty?
        ok "No queries detected that lasted longer than #{ config[:query_time_to_report] } ms in the last #{ config[:logfile_lines] } lines of logs."
      end

      longest_query = queries.sort.last

      initialize_file_cache file_cache_location unless File.exist?(file_cache_location)

      if File.read(file_cache_location) != full_query_lines[longest_query]
        write_file_cache_message file_cache_location, full_query_lines[longest_query]

        if longest_query > ( config[:query_time_to_report].to_f*10 )
          critical "Very long running query:\n #{ full_query_lines[longest_query] }"
        else
          warning "Long running query:\n #{ full_query_lines[longest_query] }"
        end
      else
        ok "Detected same query... Switching state back to normal until next long query is detected."
      end
    else
      ok "#{ config[:logfile] } does not exist." #TODO REFACTOR
    end
  end
end
