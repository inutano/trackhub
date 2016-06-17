require 'net/https'
require 'uri'
require 'json'

def request_token(username, userpass)
  server='https://www.trackhubregistry.org'
  path = '/api/login'

  url = URI.parse(server)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(path)
  request.basic_auth(username, userpass)
  response = http.request(request)

  if response.code != "200"
    puts "Invalid response: #{response.code}"
    puts response.body
    exit
  end

  result = JSON.parse(response.body)
  puts "Logged in [#{result["auth_token"]}]"
end

namespace :registry do
  username = ENV['username']
  userpass = ENV['userpass']
  task :request_token do
    request_token(username, userpass)
  end
end
