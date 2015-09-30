
include ApplicationCookbook::ResourceBase

actions :create, :destroy
default_action :create

attribute :name,              :kind_of => String, :name_attribute => true
attribute :size,              :kind_of => Integer, :default => 256
attribute :primary_directory, :kind_of => String
attribute :sub_directories,   :kind_of => Hash, :default => {}
attribute :params,            :kind_of => [Array, Hash], :default => []
attribute :type,              :kind_of => String, :default => "SATA"