name "base-ubuntu"
description "Base role applied to all Gloto Ubuntu nodes."
default_attributes()
override_attributes(
  "chef-client" => {
    "init_style" => "upstart"
  }
)
run_list(
  "recipe[gloto-chef-cookbook::apt-update]",
  "role[base]"
)
