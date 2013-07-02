name "base"
description "Base role applied to all Gloto nodes."
default_attributes(
  "ntp" => {
    "servers" => [
      "0.pool.ntp.org",
      "1.pool.ntp.org",
      "2.pool.ntp.org",
      "3.pool.ntp.org"
    ]
  }
)
override_attributes(
  "chef-client" => {
    "init_style" => "init"
  }
)
run_list(
  "recipe[chef-client::delete_validation]",
  "recipe[chef-client::service]",
  "recipe[build-essential]",
  "recipe[ntp]"
)
