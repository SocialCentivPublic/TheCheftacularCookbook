
node.set['graylog2']['password_secret']            = node['TheCheftacularCookbook']['graylog2']['password_secret']
node.set['graylog2']['root_password_sha2']         = node['TheCheftacularCookbook']['graylog2']['root_password_sha2']
node.set['graylog2']['web']['secret']              = node['graylog2']['password_secret']
node.set['graylog2']['rest']['admin_access_token'] = node['graylog2']['password_secret']
