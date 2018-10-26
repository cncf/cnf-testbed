require "rubygems"
require "json"
require "net/http"
require "uri"

# 1. Get project id from project name
# 1.a. Get all projects
# 1.b  Get Project ID for listed project
# 2. Get facility ID for facility name
# 3. Upsert SSH key
# 4. Get 1st and 2nd device ids for each server names
# 5. Get 1st (bonded), 2nd (1st interface), and 3rd (2nd interface) ports for each device id
# 6. Debond 1 port (2nd)
# 7. Upsert 1st and 2nd vlans
# 8. Convert 3rd port to layer 2
# 9. Assign 2nd port to 1st vlan
# 10. Assign 3rd port to 2nd vlan 
# 11. Assign ip address to 2nd and 3rd ports

# curl -X GET --header 'Accept: application/json' --header 'X-Auth-Token: YOURTOKEN' 'https://api.packet.net/projects/1e31983a-4a72-44b6-89e4-c12989472856'
api_token = ENV['PACKET_API_TOKEN']  
project_id ="1e31983a-4a72-44b6-89e4-c12989472856" 
packet_url = "https://#{ENV['PACKET_API_URL']}/projects/#{project_id}"
packet_uri = URI::encode(packet_url)
uri = URI.parse(packet_uri)

project = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
	request = Net::HTTP::Get.new uri 
	# request.add_field('Accept', 'application/json')
	request.add_field("X-Auth-Token", "#{api_token}")
	### json body examle ###
	# request.body = {
	# 	"topic" => topic,
	# 	"event" => "msg",
	# 	"scope" => "public",
	# 	"payload" => {"name" => name, "message" => message}.to_json}.to_json
	http.request request
end
# require "debug"
parsed_project = JSON.parse(project.body) # returns a hash
p project 
p parsed_project 
