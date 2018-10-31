require "rubygems"
require "json"
require "net/http"
require "uri"
require 'optparse'
require './packet_http'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: l2_packet_networking.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

api_token = ENV['PACKET_API_TOKEN']  

packet_url = "https://#{ENV['PACKET_API_URL']}"
phttp = PacketHttp.new(api_token, packet_url)

# 1. Get project id from project name
# 1.a. Get all projects
projects = phttp.api(url_extention: "/projects")
p "Projects: #{projects}" if options[:verbose]
parsed_projects = JSON.parse(projects.body) # returns a hash
# p "Parsed Projects: #{parsed_projects}"  if options[:verbose]
# p parsed_projects 
# 1.b  Get Project ID for listed project
selected_project = parsed_projects["projects"].find{|x| x["name"]=="#{ENV['PACKET_PROJECT_NAME']}"}
p "Selected Project: #{selected_project}"  if options[:verbose]
project_id = selected_project["id"] if selected_project
p "project_id: #{project_id}"  if options[:verbose]
# 2. Get facility ID for facility name (use env)
# 3. Upsert SSH key (done in the terraform setup)
# 4. Get 1st and 2nd device ids for each server names
devices = phttp.api(url_extention: "/projects/#{project_id}/devices")
parsed_devices = JSON.parse(devices.body) 
selected_1st_device = parsed_devices["devices"].find{|x| x["hostname"]=="#{ENV['PACKET_1ST_SERVERNAME']}"}
p "Selected 1st Server: #{selected_1st_device}"  if options[:verbose]
selected_2nd_device = parsed_devices["devices"].find{|x| x["hostname"]=="#{ENV['PACKET_2ND_SERVERNAME']}"}
p "Selected 2nd Server: #{selected_2nd_device}"  if options[:verbose]

[selected_1st_device, selected_2nd_device].each do |device|

  # 5. Get 1st (bonded), 2nd (1st interface), and 3rd (2nd interface) ports for each device id
  bonded_port = device["network_ports"].find{|x| x["name"]=="bond0"}
  p "bonded_port: #{bonded_port}"  if options[:verbose]
  eth0_port = device["network_ports"].find{|x| x["name"]=="eth0"}
  p "eth0_port: #{eth0_port}"  if options[:verbose]
  eth1_port = device["network_ports"].find{|x| x["name"]=="eth1"}
  p "eth1_port: #{eth1_port}"  if options[:verbose]
  # 6. Debond 1 port (2nd)
  debond_eth1_response = phttp.api(post: true, url_extention: "/ports/#{eth1_port['id']}/disbond")
  parsed_response = JSON.parse(debond_eth1_response.body) 
  p "parsed debond_response: #{parsed_response}"  if options[:verbose]
  # 7. Upsert 1st and 2nd vlans
  # 7.a get list of lans
  vlans_response = phttp.api(url_extention: "/projects/#{project_id}/virtual-networks")
  parsed_vlans = JSON.parse(vlans_response.body) 
  p "parsed vlans_response: #{parsed_vlans}"  if options[:verbose]
  # 7.b Get existing vlan if it exists by description
  vlan1 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{ENV['PACKET_VLAN1_DESCRIPTION']}"}
  p "existing_vlan1: #{vlan1}"  if options[:verbose]
  vlan2 = parsed_vlans["virtual_networks"].find{|x| x["description"] == "#{ENV['PACKET_VLAN2_DESCRIPTION']}"}
  p "existing_vlan2: #{vlan2}"  if options[:verbose]
  # 7.b Create new Vlans, vxlan = vlan
  unless vlan1
    vlan1_response = phttp.api(post: true, 
                               url_extention: "/projects/#{project_id}/virtual-networks",
                               request_body: {
                                 "project_id" => project_id,
                                 "description" => "#{ENV['PACKET_VLAN1_DESCRIPTION']}",
                                 "facility" => device["facility"]["code"], 
                                 "vxlan" => ENV["PACKET_VLAN1_VXLANID"],
                                 "vlan" => ENV["PACKET_VLAN1_VLANID"]
                               })
    vlan1 = JSON.parse(vlan1_response.body) 
    p "parsed vlan1: #{vlan1}"  if options[:verbose]
  end
  unless vlan2
    vlan2_response = phttp.api(post: true, 
                               url_extention: "/projects/#{project_id}/virtual-networks",
                               request_body: {
                                 "project_id" => project_id,
                                 "description" => "#{ENV['PACKET_VLAN2_DESCRIPTION']}",
                                 "facility" => device["facility"]["code"], 
                                 "vxlan" => ENV["PACKET_VLAN2_VXLANID"],
                                 "vlan" => ENV["PACKET_VLAN2_VLANID"]
                               })
    vlan2 = JSON.parse(vlan2_response.body) 
    p "parsed vlan2: #{vlan2}"  if options[:verbose]
  end
  # 8. Convert 3rd port to layer 2 (don't need to do this ... the disbond makes the network a 'hybrid' network
  # p "vlan1 id: #{vlan1["id"]}"  if options[:verbose]
  # p "vxlan id: #{vlan1["vxlan"]}"  if options[:verbose]
  # convert_eth1_response = phttp.api(post: true, 
  #                                   url_extention: "/ports/#{eth1_port['id']}/convert/layer-2",
  #                                  request_body: {
  #                                     "vnid" => "#{vlan1["id"]}"
  #                                   })
  # parsed_response = JSON.parse(convert_eth1_response.body) 
  # p "parsed convert_eth1_response: #{parsed_response}"  if options[:verbose]

  # # 9. Assign 2nd port to 1st vlan (don't do this, lease 1st nic bonded)
  #
  # 10. Assign 3rd port to 2nd vlan 
  p "vlan2 id: #{vlan2["id"]}"  if options[:verbose]
  p "vxlan id: #{vlan2["vxlan"]}"  if options[:verbose]
  assign_vlan2_response = phttp.api(post: true, 
                                    url_extention: "/ports/#{eth1_port['id']}/assign",
                                    request_body: {
                                      "vnid" => "#{vlan2["id"]}"
                                    })
  parsed_response = JSON.parse(assign_vlan2_response.body) 
  p "parsed assign_eth1_response: #{parsed_response}"  if options[:verbose]
end
# 11. Assign ip address to 2nd and 3rd ports (don't do this, terraform is handling)

