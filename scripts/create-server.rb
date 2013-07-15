#!/usr/bin/env ruby

require_relative "./script_utils"

IDENTITY_FILE="aws-gloto"
AMI_ID="ami-d0f89fb9"
SSH_USER="ubuntu"

unless ENV["AWS_SSH_KEY"] && File.exist?(ENV["AWS_SSH_KEY"])
  raise "Please set the environment variable AWS_SSH_KEY to point to the amazon key"
end

def present_menu(title, values, choices, default = nil)
  puts ""
  puts ""
  choices.each_with_index do |choice, index|
    puts " #{index + 1}: #{choice}"
  end
  puts ""
  if default
    print "#{title} (default: #{choices[default]}): "
  else
    print "#{title}: "
  end
  values[gets.strip.to_i - 1]
end

security_groups = run_command("ec2-describe-group | grep vpc").map do |line|
  _, id, _, name, description, _ = line.split("\t")
  {id: id, name: name, description: description}
end

subnets = load_subnets

flavors = ["t1.micro", "m1.small", "m1.medium", "m1.large"]

print "Enter a name for the new instance: "
name = gets.strip

group =  present_menu("Security group", security_groups, security_groups.map { |group| group[:name] })
subnet = present_menu("Subnet", subnets, subnets.map { |subnet| "%-15s %s" % [subnet[:name], subnet[:cidr]] })
flavor = present_menu("Machine type", flavors, flavors, 2)

puts <<-EOS

Creating new EC2 machine:

  Name:           #{name}
  Flavor:         #{flavor}
  Security group: #{group[:name]}
  Subnet:         #{subnet[:id]} (#{subnet[:name]})

EOS

print "Continue (y/n)? "
confirm = gets.strip

if confirm.downcase.eql?("y")
  command = <<-EOS
knife ec2 server create \
  --flavor #{flavor} \
  --identity-file #{IDENTITY_FILE} \
  --image #{AMI_ID} \
  --security-group-ids #{group[:id]} \
  --subnet #{subnet[:id]} \
  --ssh-user #{SSH_USER} \
  --node-name #{name} \
  --identity-file #{ENV["AWS_SSH_KEY"]}
  EOS
  run_command(command.strip, true)
else
  $stderr.puts "Instance creation aborted!"
end
