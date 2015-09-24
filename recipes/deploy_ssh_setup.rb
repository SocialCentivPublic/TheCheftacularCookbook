# Install sshkey gem into chef
chef_gem 'sshkey'
require 'sshkey'

user_hashes = {
  node['cheftacular']['deploy_user'] => {
    "location" => "/home/#{ node['cheftacular']['deploy_user'] }/.ssh"
  },
  "root" => {
    "location" => "/root/.ssh"
  }
}

deploy_keys_arr         = []
specific_keys_arr       = []
authentication_bag_hash = Chef::EncryptedDataBagItem.load('default', 'authentication', node['secret']).to_hash

user_hashes.each_pair do |username, config_hash|
  ssh_loc = config_hash['location']

  # Generate a keypair with Ruby
  sshkey = SSHKey.generate(
    type: 'RSA',
    comment: "#{ node['cheftacular']['deploy_user'] }@#{ node_address_hash['dn'] }"
  )

  # Create ~/.ssh directory
  directory ssh_loc do
    owner     username
    group     username
    mode      "0744"
    recursive true
  end

  # Store private key on disk
  file "#{ ssh_loc }/id_rsa" do
    owner   username
    group   username
    content sshkey.private_key
    mode    '0600'
    action  :create_if_missing
  end

  # Store public key on disk
  file "#{ ssh_loc }/id_rsa.pub" do
    owner   username
    group   username
    content sshkey.ssh_public_key
    mode    '0644'
    action  :create_if_missing
  end

  ruby_block "#{ username }-save-pubkey" do
    block do
      node.set_unless["#{ username }_public_key"] = File.read("#{ ssh_loc }/id_rsa.pub")
    end
  end

  node['applications'].each_key do |app_name|
    if authentication_bag_hash['specific_repository_authorized_keys'].has_key?(app_name) && !authentication_bag_hash['specific_repository_authorized_keys'][app_name].empty?
      specific_keys_arr << authentication_bag_hash['specific_repository_authorized_keys'][app_name]
    end
  end

  search(:node, "#{ username }_public_key:*") do |n|
    deploy_keys_arr << n["#{ username }_public_key"] unless n['ipaddress'] == node['ipaddress']
  end
end

template "#{ user_hashes['deploy']['location'] }/authorized_keys" do
  source 'deploy.authorized_keys.erb'
  owner  node['cheftacular']['deploy_user']
  group  node['cheftacular']['deploy_user']
  mode   '0664'
  variables(
    deploy_keys_arr:   deploy_keys_arr,
    dev_keys:          authentication_bag_hash['authorized_keys'],
    specific_dev_keys: specific_keys_arr.flatten.uniq
  )
end
