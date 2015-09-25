#!/usr/bin/env ruby
#  encoding: UTF-8
#  longest-running-query-metric
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
#      /opt/sensu/embedded/bin/ruby /etc/sensu/plugins/longest-running-query-metric.rb -f /path/to/codebase/log/file
#
#  LICENSE:
#    Louis Alridge louis@socialcentiv.com (loualrid@gmail.com)
#    Released under the same terms as Sensu (the MIT license); see LICENSE
#    for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'


#
# LongestRunningQueryMetric
#
class LongestRunningQueryMetric < Sensu::Plugin::Metric::CLI::Graphite
  option :logfile,
         description: 'Log file to check against',
         short: '-f LOGFILE',
         long: '--file LOGFILE'

  option :logfile_lines,
         description: 'Specify how many log file lines to examine. Defaults to 5000',
         short: '-n LINES',
         long: '--number LINES',
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

  def run
    timestamp = Time.now.to_i

    queries, complete_ar_queries = [],[]

    if File.exist?(config[:logfile])
      parsed_log_data = scrub(`tail -#{ config[:logfile_lines].to_i } #{ config[:logfile] }`.to_s)

      parsed_log_data.scan(/\(([\d]+\.\d)ms\)/).flatten.each do |query|
        queries << query.to_f
      end

      parsed_log_data.scan(/\| ActiveRecord: ([\d]+\.\d)ms\)/).flatten.each do |query|
        complete_ar_queries << query.to_f
      end

      output "#{ config[:scheme] }.individual_queries_longer_than_100_ms_from_last_#{ config[:logfile_lines] }_of_logs", queries.count { |f| f >= 100.0 }, timestamp

      output "#{ config[:scheme] }.individual_queries_longer_than_1000_ms_from_last_#{ config[:logfile_lines] }_of_logs", queries.count { |f| f >= 1000.0 }, timestamp

      output "#{ config[:scheme] }.individual_queries_longer_than_10000_ms_from_last_#{ config[:logfile_lines] }_of_logs", queries.count { |f| f >= 10000.0 }, timestamp

      output "#{ config[:scheme] }.individual_queries_longer_than_100000_ms_from_last_#{ config[:logfile_lines] }_of_logs", queries.count { |f| f >= 100000.0 }, timestamp

      output "#{ config[:scheme] }.total_individual_queries_from_last_#{ config[:logfile_lines] }_of_logs", queries.count, timestamp

      output "#{ config[:scheme] }.longest_running_individual_query_from_last_#{ config[:logfile_lines] }_of_logs", queries.sort.last, timestamp

      output "#{ config[:scheme] }.complete_activerecord_requests_longer_than_100_ms_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.count { |f| f >= 100.0 }, timestamp

      output "#{ config[:scheme] }.complete_activerecord_requests_longer_than_1000_ms_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.count { |f| f >= 1000.0 }, timestamp

      output "#{ config[:scheme] }.complete_activerecord_requests_longer_than_10000_ms_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.count { |f| f >= 10000.0 }, timestamp

      output "#{ config[:scheme] }.complete_activerecord_requests_longer_than_100000_ms_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.count { |f| f >= 100000.0 }, timestamp

      output "#{ config[:scheme] }.total_complete_activerecord_requests_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.count, timestamp

      output "#{ config[:scheme] }.longest_running_complete_activerecord_request_from_last_#{ config[:logfile_lines] }_of_logs", complete_ar_queries.sort.last, timestamp

      ok
    else
      ok "#{ config[:logfile] } does not exist." #TODO REFACTOR
    end
  end
end
