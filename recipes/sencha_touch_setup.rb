
include_recipe "java"

unless node["setup_sencha_cmd_#{ node['sencha_cmd']['version'] }"]
  # Install from apt repositories
  %w{libc6:i386 libncurses5:i386 libstdc++6:i386 unzip npm}.each do |pkg|
    package pkg do
      action :install
    end
  end

  remote_file "/tmp/sencha-cmd.zip" do
    source "http://cdn.sencha.io/cmd/#{ node['sencha_cmd']['version'] }/SenchaCmd-#{ node['sencha_cmd']['version'] }-linux-x64.run.zip"
    action :create
  end

  bash "install SenchaCmd" do
    code <<-EOH
      unzip /tmp/sencha-cmd.zip
      chmod +x SenchaCmd-#{ node['sencha_cmd']['version'] }-linux-x64.run
      ./SenchaCmd-#{ node['sencha_cmd']['version'] }-linux-x64.run --prefix /opt/sencha --mode unattended
    EOH
  end

  node.set["setup_sencha_cmd_#{ node['sencha_cmd']['version'] }"] = true
end
