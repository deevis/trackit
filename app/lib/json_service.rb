module JsonService
  def json_service(url)
    puts "Requesting: #{url}"
    response = RestClient.get url 
    puts "Response Size: #{response.body.size} "
    data = JSON.parse(response.body)
    return data
  rescue => e 
    puts "Got 503 response code: #{e.inspect}"
    return nil
  end
end