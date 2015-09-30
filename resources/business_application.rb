
include ApplicationCookbook::ResourceBase

actions :create, :destroy
default_action :create

attribute :name,      :kind_of => String, :name_attribute => true
attribute :type,      :kind_of => String, :equal_to => ['ruby_on_rails', 'lamp', 'nodejs']
attribute :role_name, :kind_of => String
attribute :params,    :kind_of => [Array, Hash], :default => []