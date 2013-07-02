## Chef Server
#
# Required environment variabled:
#
# AWS_ACCESS_KEY
# AWS_SECRET_KEY
# AWS_SSH_KEY_ID
#
# Optional environment variable overrides:
#
# CHEF_USER - defaults to ENV["USER"]
# CHEF_CLIENT_KEY - defaults to "#{chef_dir}/#{node_name}.pem"
#

chef_dir = ENV["CHEF_DIRECTORY"] || File.dirname(__FILE__)

# Logging details
log_level                :info
log_location             STDOUT

# Username and key
node_name                (ENV["CHEF_USER"] || ENV["USER"] || ENV["USERNAME"]).downcase
client_key               (ENV["CHEF_CLIENT_KEY"] || "#{chef_dir}/#{node_name}.pem")

validation_client_name   "chef-validator"
validation_key           "#{chef_dir}/chef-validator.pem"

chef_server_url          "https://chef-server.gloto.com"
syntax_check_cache_path  "#{chef_dir}/syntax_check_cache"
cookbook_path            [File.join(chef_dir, "..", "cookbooks")]

if ENV["AWS_ACCESS_KEY"] && ENV["AWS_SECRET_KEY"] && ENV["AWS_SSH_KEY_ID"]
  knife[:aws_access_key_id] = ENV["AWS_ACCESS_KEY"]
  knife[:aws_secret_access_key] = ENV["AWS_SECRET_KEY"]
  knife[:aws_ssh_key_id] = ENV["AWS_SSH_KEY_ID"]
else
  raise "Amazon credentials not found in environment. Please set AWS_ACCESS_KEY, AWS_SECRET_KEY, and AWS_SSH_KEY_ID"
end
