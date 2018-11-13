
require "rubygems"
require "json"
require "net/http"
require "uri"
require 'optparse'
require_relative './packet_http'
require 'pp'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: l2_packet_networking.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-nPROJECTNAME", "--project-name=PROJECT", "Project name") do |n|
    options[:project_name] = n
  end
  opts.on("-nSERVER", "--server=SERVER", "Server name") do |n|
    options[:server] = n
  end
  opts.on("-nINSTANCE", "--instance-id=INSTANCEID", "Instance ID") do |n|
    options[:instance_id] = n
  end

  opts.on("-nVLAN", "--create-vlan=VLAN", "VLAN to create") do |n|
    options[:create_vlan] = n
  end
  opts.on("-nVLAN", "--delete-vlan=VLAN", "VLAN to delete") do |n|
    options[:delete_vlan] = n
  end
  opts.on("-nINTERFACE", "--disbond-interface=INTERFACE", "Interface to disbond") do |n|
    options[:disbond_port] = n
  end
  opts.on("-nINTERFACE", "--bond-interface=INTERFACE", "Interface to bond") do |n|
    options[:bond_port] = n
  end
  opts.on("-nVLAN", "--assign-vlan=VLAN", "VLAN to assign to a port. use --assign-vlan-port to designate port") do |n|
    options[:assign_vlan] = n
  end
  opts.on("-nVLANPORT", "--assign-vlan-port=VLANPORT", "INTERFACE to assign to VLAN") do |n|
    options[:assign_vlan_port] = n
  end
  opts.on("-nVLAN", "--unassign-vlan=VLAN", "VLAN to unassign to a port. use --unassign-vlan-port to designate port") do |n|
    options[:unassign_vlan] = n
  end
  opts.on("-nVLANPORT", "--unassign-vlan-port=VLANPORT", "INTERFACE to unassign VLAN") do |n|
    options[:unassign_vlan_port] = n
  end
  opts.on("-nTOKEN", "--token=TOKEN", "API TOKEN") do |n|
    options[:token] = n
  end
  opts.on("-nFACILITY", "--facility=FACILITY", "Facility where the work will be performed") do |n|
    options[:facility] = n
  end
  opts.on("-nPACKETURL", "--packet-url=PACKETURL", "Packet url e.g. api.packet.net") do |n|
    options[:packet_url] = n
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts 
    exit
  end
end.parse!

pp options  if options[:verbose]
pp ARGV if options[:verbose]

if options[:bond_port].nil? && options[:delete_vlan].nil? && options[:unassign_vlan].nil? && options[:assign_vlan].nil? && options[:disbond_port].nil? && options[:create_vlan].nil?
  puts "You must select delete_vlan, unassign_vlan, assign-vlan, bond-interface, disbond-interface, or create vlan!"
  exit
end
if options[:unassign_vlan] && (options[:unassign_vlan_port].nil? || (options[:server].nil? && options[:instance_id].nil?))
  puts "You must provide a vlan port and server (or instance id) if you select unassign-vlan!"
  exit
end
if options[:assign_vlan] && (options[:assign_vlan_port].nil? || (options[:server].nil? && options[:instance_id].nil?))
  puts "You must provide a vlan port and server (or instance id) if you select assign-vlan!"
  exit
end

if options[:create_vlan] &&  options[:facility].nil?
  puts "You must provide a facility to call create-vlan!"
  exit
end

if options[:delete_vlan] &&  options[:facility].nil?
  puts "You must provide a facility to call delete-vlan!"
  exit
end
if options[:bond_port] && (options[:server].nil? && options[:instance_id].nil?)
  puts "You must provide a server (or instance id) if you select bond-interface!"
  exit
end
if options[:disbond_port] && (options[:server].nil? && options[:instance_id].nil?)
  puts "You must provide a server (or instance id) if you select disbond-interface!"
  exit
end
if options[:token]
  api_token = options[:token]  
else
  api_token = "#{ENV['PACKET_API_TOKEN']}"
end

if options[:packet_url]
  packet_url = "https://#{options[:packet_url]}"
else
  packet_url = "https://#{ENV['PACKET_API_URL']}"
end

if options[:project_name]
  project_name = options[:project_name]
else
  project_name = "#{ENV['PACKET_PROJECT_NAME']}"
end

if options[:facility]
  facility = options[:facility]
else
  facility = "#{ENV['FACILITY']}"
end
phttp = PacketHttp.new(api_token, packet_url)

# 1. Get project id from project name
# 1.a. Get all projects
projects = phttp.api(url_extention: "/projects")
p "Projects: #{projects}" if options[:verbose]
parsed_projects = JSON.parse(projects.body) # returns a hash
# 1.b  Get Project ID for listed project
selected_project = parsed_projects["projects"].find{|x| x["name"]=="#{project_name}"}
p "Selected Project: #{selected_project}"  if options[:verbose]
project_id = selected_project["id"] if selected_project
p "project_id: #{project_id}"  if options[:verbose]
# 2. Get facility ID for facility name (use env)
# 3. Upsert SSH key (done in the terraform setup)
# 4. Get 1st and 2nd device ids for each server names

if options[:server] or options[:instance_id]
  devices = phttp.api(url_extention: "/projects/#{project_id}/devices?per_page=1000")
  parsed_devices = JSON.parse(devices.body) 

  if options[:instance_id]
    selected_1st_device = parsed_devices["devices"].find{|x| x["id"]=="#{options[:instance_id]}"}
  else
    selected_1st_device = parsed_devices["devices"].find{|x| x["hostname"]=="#{options[:server]}"}
  end

  if selected_1st_device.nil?
    if options[:instance_id]
      puts "Could not find device with instance ID '#{options[:instance_id]}'"
    else
      puts "Could not find device with hostname '#{options[:server]}'"
    end
    exit 1
  end

  p "Selected 1st Server: #{selected_1st_device}"  if options[:verbose]
  device = selected_1st_device
end

# 5. Get 1st (bonded), 2nd (1st interface), and 3rd (2nd interface) ports for each device id
# 6. Debond 1 port (2nd)
if options[:disbond_port]
  disbond_port = device["network_ports"].find{|x| x["name"]==options[:disbond_port]}
  p "disbond_port: #{disbond_port}"  if options[:verbose]
  disbond_response = phttp.api(post: true, url_extention: "/ports/#{disbond_port['id']}/disbond")
  parsed_response = JSON.parse(disbond_response.body) 
  p "parsed disbond_response: #{parsed_response}"  if options[:verbose]
  if parsed_response["id"]
    puts "success"
  else 
    puts "failure"
  end
end

if options[:bond_port]
  bond_port = device["network_ports"].find{|x| x["name"]==options[:bond_port]}
  p "bond_port: #{bond_port}"  if options[:verbose]
  bond_response = phttp.api(post: true, url_extention: "/ports/#{bond_port['id']}/bond")
  parsed_response = JSON.parse(bond_response.body) 
  p "parsed bond_response: #{parsed_response}"  if options[:verbose]
  if parsed_response["id"]
    puts "success"
  else 
    puts "failure"
  end
end
# 7. Upsert 1st and 2nd vlans
# 7.a get list of lans
if options[:create_vlan]
  vlans_response = phttp.api(url_extention: "/projects/#{project_id}/virtual-networks")
  parsed_vlans = JSON.parse(vlans_response.body) 
  p "parsed vlans_response: #{parsed_vlans}"  if options[:verbose]
  # 7.b Get existing vlan if it exists by description
  vlan1 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{options[:create_vlan]}"}
  p "existing_vlan1: #{vlan1}"  if options[:verbose]
  # 7.b Create new Vlans, vxlan = vlan
  unless vlan1
    # it seems vxlan and vlan ids are ignored (assigned by packet)
    vlan1_response = phttp.api(post: true, 
                               url_extention: "/projects/#{project_id}/virtual-networks",
                               request_body: {
                                 "project_id" => project_id,
                                 "description" => "#{options[:create_vlan]}",
                                 "facility" => facility, 
                                 "vxlan" => 0,
                                 "vlan" => 0 
                               })
    vlan1 = JSON.parse(vlan1_response.body) 
    p "parsed vlan1: #{vlan1}"  if options[:verbose]
  end
  puts vlan1["vxlan"]
end

if options[:delete_vlan]
  vlans_response = phttp.api(url_extention: "/projects/#{project_id}/virtual-networks")
  parsed_vlans = JSON.parse(vlans_response.body) 
  p "parsed vlans_response: #{parsed_vlans}"  if options[:verbose]
  # 7.b Get existing vlan if it exists by description
  vlan1 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{options[:delete_vlan]}"}
  p "existing_vlan1: #{vlan1}"  if options[:verbose]
  # 7.b Create new Vlans, vxlan = vlan
  if vlan1
    # it seems vxlan and vlan ids are ignored (assigned by packet)
    vlan1_response = phttp.api(delete: true, 
                               url_extention: "/virtual-networks/#{vlan1['id']}")
    p "vlan1 response: #{vlan1}"  if options[:verbose]
  end
  if vlan1.nil? || (vlan1 && vlan1["id"])
    puts 'success'
  else 
    puts 'failure'
  end
end
# 8. Convert 3rd port to layer 2 (don't need to do this ... the disbond makes the network a 'hybrid' network
# 9. Assign 2nd port to 1st vlan (don't do this, lease 1st nic bonded)
# 10. Assign 3rd port to 2nd vlan 
if options[:assign_vlan]
  # find vland based on description
  vlans_response = phttp.api(url_extention: "/projects/#{project_id}/virtual-networks")
  parsed_vlans = JSON.parse(vlans_response.body) 
  p "parsed vlans_response: #{parsed_vlans}"  if options[:verbose]
  # 7.b Get existing vlan if it exists by description
  vlan1 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{options[:assign_vlan]}"}
  p "existing_vlan1: #{vlan1}"  if options[:verbose]
  vlan_port = device["network_ports"].find{|x| x["name"]==options[:assign_vlan_port]}
  p "vlan port: #{vlan_port}"  if options[:verbose]
  p "vlan port id: #{vlan_port["id"]}"  if options[:verbose]
  assign_vlan_response = phttp.api(post: true, 
                                   url_extention: "/ports/#{vlan_port['id']}/assign",
                                   request_body: {
                                     "vnid" => "#{vlan1["id"]}"
                                   })
  parsed_response = JSON.parse(assign_vlan_response.body) 
  p "parsed assign_vlan_response: #{parsed_response}"  if options[:verbose]
  if parsed_response["id"] || (parsed_response["errors"] && parsed_response["errors"].find{|x| x =~ /already assigned/})
    puts "success"
  else
    puts "failure"
  end
end

if options[:unassign_vlan]
  # find vland based on description
  vlans_response = phttp.api(url_extention: "/projects/#{project_id}/virtual-networks")
  parsed_vlans = JSON.parse(vlans_response.body) 
  p "parsed vlans_response: #{parsed_vlans}"  if options[:verbose]
  # 7.b Get existing vlan if it exists by description
  vlan1 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{options[:unassign_vlan]}"}
  p "existing_vlan1: #{vlan1}"  if options[:verbose]
  vlan_port = device["network_ports"].find{|x| x["name"]==options[:unassign_vlan_port]}
  p "vlan port: #{vlan_port}"  if options[:verbose]
  p "vlan port id: #{vlan_port["id"]}"  if options[:verbose]
  unassign_vlan_response = phttp.api(post: true, 
                                     url_extention: "/ports/#{vlan_port['id']}/unassign",
                                     request_body: {
                                       "vnid" => "#{vlan1["id"]}"
                                     })
  parsed_response = JSON.parse(unassign_vlan_response.body) 
  p "parsed unassign_vlan_response: #{parsed_response}"  if options[:verbose]
  if parsed_response["id"] || (parsed_response["errors"] && parsed_response["errors"].find{|x| x =~ /not assigned/})
    puts "success"
  else
    puts "failure"
  end
end
# 11. Assign ip address to 2nd and 3rd ports (don't do this, terraform is handling)

