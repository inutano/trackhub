require 'net/https'
require 'uri'
require 'json'

module TrackHub
  class Client
    def initialize(username, userpass)
      @username = username
      @userpass = userpass
    end

    def server_url
      'https://www.trackhubregistry.org'
    end

    def login
      path = '/api/login'
      url = URI.parse(server_url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(path)
      request.basic_auth(@username, @userpass)
      response = http.request(request)

      if response.code != "200"
        puts "Invalid response: #{response.code}"
        puts response.body
        exit 1
      end

      result = JSON.parse(response.body)
      @auth_token = result["auth_token"]
      puts "Logged in: [#{result["auth_token"]}]"
    end

    def logout
      request = Net::HTTP::Get.new('/api/logout', { 'User' => @username, 'Auth-Token' => @auth_token })
      response = $http.request(request)

      if response.code != "200"
        puts "Invalid response: #{response.code}"
        puts response.body
        exit 1
      end

      puts 'Logged out'
    end

    def genome_assemblies
      {
        'hg19' => 'GCA_000001405.1',
        'mm9' => 'GCA_000001635.1',
        'dm3' => '',
        'ce10' => 'GCA_000002985.2',
        'sacCer3' => 'GCA_000146045.2',
      }
    end

    def register(hub_url)
      url = URI.parse(server_url)
      $http = Net::HTTP.new(url.host, url.port)
      $http.use_ssl = true
      $http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      self.login

      request = Net::HTTP::Post.new('/api/trackhub', { 'Content-Type' => 'application/json', 'User' => @username, 'Auth-Token' => @auth_token })
      request.body = { 'url' => hub_url, 'assemblies' => genome_assemblies }.to_json

      # make a request and register, catch response
      response = $http.request(request)
      if response.code != "201"
        puts "Invalid response: #{response.code} #{response.body}"
        exit
      end
      puts "Registered hub at #{hub_url}"

      # logout
      logout
    end
  end
end

namespace :registry do
  username = ENV['username']
  userpass = ENV['userpass']
  hub_url  = ENV['hub_url']

  desc "Request authentication token"
  task :regist do
    TrackHub::Client.new(username, userpass).register(hub_url)
  end
end
