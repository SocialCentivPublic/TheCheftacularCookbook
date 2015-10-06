# Install sshkey gem into chef
chef_gem 'sshkey'


# Generate a keypair with Ruby
require 'sshkey'
sshkey = SSHKey.generate(
  type: 'RSA',
  comment: "rep@#{ node_address_hash['dn'] }"
)

#yes, this is the home directory for the postgres user AFTER IT HAS BEEN SETUP by postgres
pkey_loc = "/var/lib/postgresql/.ssh"

# Create ~/.ssh directory
directory pkey_loc do
  owner     'postgres'
  group     'postgres'
  mode      "0744"
  recursive true
end

# Store private key on disk
file "#{ pkey_loc }/id_rsa" do
  owner   'postgres'
  group   'postgres'
  content sshkey.private_key
  mode    '0600'
  action  :create_if_missing
end

# Store public key on disk
file "#{ pkey_loc }/id_rsa.pub" do
  owner   'postgres'
  group   'postgres'
  content sshkey.ssh_public_key
  mode    '0644'
  action  :create_if_missing
end

ruby_block 'postgres-save-pubkey' do
  block do
    # Save public key to chef-server as node data
    node.set['postgres_public_key'] = File.read("#{ pkey_loc }/id_rsa.pub")
  end
end
