require 'net/https'
require 'uri'
require 'json'

module TrackHubRegistry
  class Client
    def initialize(username, userpass)
      @username = username
      @userpass = userpass
    end

    def register(hub_url)
      @hub_url = hub_url
      server_url = URI.parse(registry_url)
      @http = Net::HTTP.new(server_url.host, server_url.port)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      login
      register_trackhub
      logout
    end

    def registry_url
      'https://www.trackhubregistry.org'
    end

    def login
      # create request and send it
      path = '/api/login'
      request = Net::HTTP::Get.new(path)
      request.basic_auth(@username, @userpass)
      response = @http.request(request)
      # Error
      raise NameError if response.code != "200"
      # retrieve result
      result = JSON.parse(response.body)
      @auth_token = result["auth_token"]
      puts "Logged in: [#{result["auth_token"]}]"
    rescue NameError
      puts "Invalid response: #{response.code}"
      puts response.body
      exit 1
    end

    def logout
      # create request and send it
      request = Net::HTTP::Get.new('/api/logout', { 'User' => @username, 'Auth-Token' => @auth_token })
      response = @http.request(request)
      raise NameError if response.code != "200"
      # log out
      puts 'Logged out'
    rescue NameError
      puts "Invalid response: #{response.code}"
      puts response.body
      exit 1
    end

    def genome_assemblies
      {
        'hg19' => 'GCA_000001405.1',
        'mm9' => 'GCA_000001635.1',
        'dm3' => 'GCA_000001215.2',
        'ce10' => 'GCA_000002985.2',
        'sacCer3' => 'GCA_000146045.2',
      }
    end

    def register_trackhub
      # create request and send it
      request = Net::HTTP::Post.new('/api/trackhub', { 'Content-Type' => 'application/json', 'User' => @username, 'Auth-Token' => @auth_token })
      request.body = { 'url' => @hub_url, 'type' => 'epigenomics' }.to_json
      # request and register, catch response
      response = @http.request(request)
      raise NameError if response.code != "201"
      puts "Registered hub at #{@hub_url}"
    rescue NameError
      puts "Invalid response: #{response.code} #{response.body}"
      exit 1
    end
  end
end

namespace :registry do
  username = ENV['username']
  userpass = ENV['userpass']
  hub_url  = ENV['hub_url']

  desc "Request authentication token"
  task :regist do
    TrackHubRegistry::Client.new(username, userpass).register(hub_url)
  end
end
