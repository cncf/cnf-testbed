class PacketHttp

  def initialize(api_token, packet_url)
    @api_token = api_token
    @packet_url = packet_url
  end

  # url_extention: '', request_body: '', post: false
  def api(options ={})

    (delete = true) if options[:delete]
    (post = true) if options[:post]
    packet_url = "#{@packet_url}#{options[:url_extention]}"
    # this next line will make the tests fail
    # p "full url: #{packet_url}"
    packet_uri = URI::encode(packet_url)
    uri = URI.parse(packet_uri)

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      if post 
        request = Net::HTTP::Post.new uri 
      elsif delete
        request = Net::HTTP::Delete.new uri 
      else
        request = Net::HTTP::Get.new uri 
      end
      request.add_field('Content-Type', 'application/json')
      request.add_field("X-Auth-Token", "#{@api_token}")
      request.body = options[:request_body].to_json if options[:request_body]
      ### json body examle -- notice internal json must be already converted ###
      # request.body = {
      # 	"topic" => topic,
      # 	"event" => "msg",
      # 	"scope" => "public",
      # 	"payload" => {"name" => name, "message" => message}.to_json}.to_json
      http.request request
    end
    response 
  end
end
