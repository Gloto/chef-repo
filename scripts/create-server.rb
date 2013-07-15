#!/usr/bin/env ruby

require "open3"

IDENTITY_FILE="aws-gloto"
AMI_ID="ami-d0f89fb9"
SSH_USER="ubuntu"

unless ENV["AWS_SSH_KEY"] && File.exist?(ENV["AWS_SSH_KEY"])
  raise "Please set the environment variable AWS_SSH_KEY to point to the amazon key"
end

def run_command(command, verbose = false)
  exit_status = nil
  output = []
  puts command if verbose
  Open3.popen3(command) do |stdin, stdout, stderr, wait_thread|
    stdout.each do |line|
      output << line.strip
      $stdout.puts(line) if verbose
    end
    stderr.each { |line| $stderr.puts line }
    exit_status = wait_thread.value.to_i
  end
  raise %Q(The command "#{command}" failed.) unless exit_status.eql? 0
  output
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

subnets = run_command("ec2-describe-subnets").reduce({}) do |memo, line|
  line = line.split("\t")
  case line[0]
  when "SUBNET"
    _, id, available, vpc, cidr, zone = line
    if available.eql?("available")
      memo[id] = { id: id, cidr: cidr }
    end
  when "TAG"
    _, _, id, key, value = line
    if key.eql?("Name") && memo[id]
      memo[id][:name] = value
    end
  end

  memo
end.values.sort do |subnet1, subnet2|
  octet1 = subnet1[:cidr].split(".")[2].to_i
  octet2 = subnet2[:cidr].split(".")[2].to_i
  octet1 <=> octet2
end

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
