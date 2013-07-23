name "git-server"
description "Hosts all of Gloto's Git repositories"
default_attributes()
override_attributes(
  :set_fqdn => "source.gloto.com",
  :ebs => {
    :creds => {
      :databag => "passwords",
      :item => "AWS",
      :encrypted => true
    },
    :volumes => {
      "/data" => { :device => "/dev/xvdf" }
    }
  }
)
run_list(
  "role[base-ubuntu]",
  "recipe[hostname]",
  "recipe[gloto-chef-cookbook::ldap-client]",
  "recipe[gloto-chef-cookbook::git-host]",
  "recipe[ebs]"
)
