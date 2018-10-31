require "rubygems"
require "json"
require "net/http"
require "uri"
require './packet_http'

api_token = ENV['PACKET_API_TOKEN']  

packet_url = "https://#{ENV['PACKET_API_URL']}"
phttp = PacketHttp.new(api_token, packet_url)
# url_extention = "/projects/#{project_id}"

# 1. Get project id from project name
# 1.a. Get all projects
projects = phttp.api(url_extention: "/projects")
p "Projects: #{projects}"
parsed_projects = JSON.parse(projects.body) # returns a hash
# p "Parsed Projects: #{parsed_projects}"
# p parsed_projects 
# 1.b  Get Project ID for listed project
selected_project = parsed_projects["projects"].find{|x| x["name"]=="#{ENV['PACKET_PROJECT_NAME']}"}
p "Selected Project: #{selected_project}"
project_id = selected_project["id"] if selected_project
p "project_id: #{project_id}"
# 2. Get facility ID for facility name
# 3. Upsert SSH key
# 4. Get 1st and 2nd device ids for each server names
devices = phttp.api(url_extention: "/projects/#{project_id}/devices")
parsed_devices = JSON.parse(devices.body) 
selected_1st_device = parsed_devices["devices"].find{|x| x["hostname"]=="#{ENV['PACKET_1ST_SERVERNAME']}"}
p "Selected 1st Server: #{selected_1st_device}"
selected_2nd_device = parsed_devices["devices"].find{|x| x["hostname"]=="#{ENV['PACKET_2ND_SERVERNAME']}"}
p "Selected 2nd Server: #{selected_2nd_device}"
# 5. Get 1st (bonded), 2nd (1st interface), and 3rd (2nd interface) ports for each device id
 bonded_port = selected_1st_device["network_ports"].find{|x| x["name"]=="bond0"}
p "bonded_port: #{bonded_port}"
 eth0_port = selected_1st_device["network_ports"].find{|x| x["name"]=="eth0"}
p "eth0_port: #{eth0_port}"
 eth1_port = selected_1st_device["network_ports"].find{|x| x["name"]=="eth1"}
p "eth1_port: #{eth1_port}"
# 6. Debond 1 port (2nd)
debond_eth1_response = phttp.api(post: true, url_extention: "/ports/#{eth1_port['id']}/disbond")
parsed_response = JSON.parse(debond_eth1_response.body) 
p "parsed debond_response: #{parsed_response}"
# 7. Upsert 1st and 2nd vlans
vlan1_response = phttp.api(post: true, 
                           url_extention: "/projects/#{project_id}/virtual-networks",
                           request_body: {
                             "project_id" => project_id,
                             "description" => "",
                             "facility" => selected_1st_device["facility"]["code"], 
                             "vxlan" => ENV["PACKET_VLAN1_VXLANID"],
                             "vlan" => ENV["PACKET_VLAN1_VLANID"]
                          })
vlan1 = JSON.parse(vlan1_response.body) 
p "parsed vlan1: #{vlan1}"
# 8. Convert 3rd port to layer 2
# 9. Assign 2nd port to 1st vlan
# 10. Assign 3rd port to 2nd vlan 
# 11. Assign ip address to 2nd and 3rd ports

# curl -X GET --header 'Accept: application/json' --header 'X-Auth-Token: YOURTOKEN' 'https://api.packet.net/projects/1e31983a-4a72-44b6-89e4-c12989472856'
project_id = "1e31983a-4a72-44b6-89e4-c12989472856" 

phttp = PacketHttp.new(api_token, packet_url)
project = phttp.api(url_extention: "/projects/#{project_id}")
# require "debug"
parsed_project = JSON.parse(project.body) # returns a hash
p project 
p parsed_project 
