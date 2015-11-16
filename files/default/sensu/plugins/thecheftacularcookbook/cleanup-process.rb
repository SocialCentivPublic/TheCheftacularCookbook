#!/usr/bin/env ruby
#
# Cleans up processes
# ===
#
# DESCRIPTION:
#   Searches for a process that has a specific string and destroys it
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   linux
#   bsd
#
# DEPENDENCIES:
#   sensu-plugin Ruby gem
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CleanupProcess < Sensu::Plugin::Check::CLI

  option :name,
    :description => "Name of process to search for and remove",
    :short => '-n NAME',
    :long => '--name Name'

  option :force,
    :description => "Use -9 to force destroy the process",
    :short => '-f',
    :long => '--force',
    :boolean => true,
    :default => false

  option :kill_all_but_newest,
    :description => "Destroys all of the processes except the newest one",
    :short => '-k',
    :long => '--all-but-newest',
    :boolean => true,
    :default => false

  def run
    procs             = `ps -efww --sort=start_time | grep -v cleanup-process.rb`
    base_line         = config[:name]
    target_procs      = {}
    target_proc_order = [] #the last entry in this array is the newest process

    procs.each_line do |proc|
      next unless proc.include?(base_line)

      proc_id = proc[/([\d]+){1}/].to_i.to_s

      target_procs[proc_id] = {}
      target_procs[proc_id]['line'] = case
                                      when proc.include?(base_line) then proc
                                      end
      target_procs_order << proc_id
    end

    target_procs.each_pair do |prc_id, proc_hash|
      next if prc_id == target_proc_order.last && config[:kill_all_but_newest]
      puts "preparing to kill #{ prc_id }"
      
      `kill #{ '-9 ' if config[:force] }#{ prc_id }`
    end

    exit 0
  end
end
