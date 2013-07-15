require "open3"

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

def load_subnets
  run_command("ec2-describe-subnets").reduce({}) do |memo, line|
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
end

def load_ec2_instances
  run_command("ec2-describe-instances").reduce({}) do |memo, line|
    line = line.split("\t")
    case line[0]
    when "INSTANCE"
      _, id, ami, external_url, internal_url, state, key, _, _, size, started_on, availability_zone,
        _, _, _, monitoring, external_ip, internal_ip, vpc, subnet = line
      memo[id] = {
        id: id,
        ami: ami,
        external_url: external_url,
        internal_url: internal_url,
        external_ip: external_ip,
        internal_ip: internal_ip,
        state: state,
        key: key,
        availability_zone: availability_zone,
        size: size,
        started_on: Time.parse(started_on),
        monitoring: monitoring,
        vpc: vpc,
        subnet: subnet,
        tags: {}
      }
    when "TAG"
      if line[1] == "instance"
        _, _, instance_id, tag, value = line
        memo[instance_id][:name] = value if tag == "Name"
        memo[instance_id][:tags][tag] = value
      end
    end
    memo
  end.values
end
