
#Negative behavior for all chef attribute node data should be here
if node['attribute_toggles']
  node['TheCheftacularCookbook']['attribute_toggles'].each_pair do |attribute, setting_hash|
    node.set['attribute_toggles'][attribute] = setting_hash['set_to'] if node['attribute_toggles'][attribute] && !node['roles'].include?(setting_hash['when']['not_include_role'])
  end
end
