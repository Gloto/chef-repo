name "git-server"
description "Hosts all of Gloto's Git repositories"
default_attributes()
override_attributes(
  :set_fqdn => "source.gloto.com"
=begin
  :ebs => {
    :creds => {
      :databag => "AWS",
      :item => "chef-server-keys",
      :encrypted => false
    },
    :volumes => {
      "/data" => { :device => "/dev/xvdf" }
    }
  }
=end
)
run_list(
  "role[base-ubuntu]",
  "recipe[hostname]"
)
