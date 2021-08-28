require 'httparty'
require 'progress_bar'
require 'persistent_httparty'
class Organization
  include HTTParty
  persistent_connection_adapter
  base_uri 'https://atom-api.kovalev.team'
  def self.fetch
    get('/org/address')
  end
end
