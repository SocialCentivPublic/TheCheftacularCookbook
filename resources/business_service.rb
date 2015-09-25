actions :create, :destroy
default_action :create

attribute :name,                    :kind_of => String, :name_attribute => true
attribute :application_name,        :kind_of => String
attribute :type,                    :kind_of => String, :equal_to => ['ruby_on_rails']
attribute :task,                    :kind_of => String
attribute :environment_vars,        :kind_of => [Array], :default => []
attribute :application_log_cleanup, :kind_of => [TrueClass, FalseClass], :default => false
attribute :delayedjob_log_cleanup,  :kind_of => [TrueClass, FalseClass], :default => false
attribute :syslog_cleanup,          :kind_of => [TrueClass, FalseClass], :default => false
