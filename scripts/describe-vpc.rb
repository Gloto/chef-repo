#!/usr/bin/env ruby

require "ap"
require "time"
require_relative "./script_utils"

subnets = load_subnets
instances = load_ec2_instances.select { |instance| instance[:state].eql? "running" }

subnets.each do |subnet|
  header = "#{subnet[:name]} (#{subnet[:cidr]})"
  puts header
  puts "-" * header.length

  instances.select { |instance| instance[:subnet].eql? subnet[:id] }.each do |instance|
    puts "#{instance[:name]} (#{instance[:internal_ip]})"
  end

  puts ""
end

puts "Not in VPC"
puts "----------"

instances.select { |instance| instance[:subnet].eql?("") }
         .each   { |instance| puts "#{instance[:name]} (#{instance[:external_ip]})" }
