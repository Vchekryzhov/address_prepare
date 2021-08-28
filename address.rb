require 'httparty'
require 'progress_bar'
require 'persistent_httparty'
require 'byebug'
require 'cgi'
require 'active_support'
require 'socket'

class Address
  def perform
    bar = ProgressBar.new(organizations.size)
    CSV.open('./addresses.csv', 'wb') do |csv|
      CSV.open('./denis.csv', 'wb') do |dcsv|
        csv << %w[id address clear_address lat lon]
        dcsv << %w[id lat lon]
        organizations.each do |organization|
          clear_address = organization['address'].downcase.gsub(/крым|станица|строение|здание|проспект|хутор|слобода|поселок|город|республика|улица|деревня|село|микро|микрорайон|область|рабочий поселок|район|поселок городского типа|переулок/, '')
                                                 .gsub(/\sдом[.,\s]+/, '')
                                                 .gsub(/\sд[.,\s]+/, '')
                                                 .gsub(/\sг[.,\s]+/, '')
                                                 .gsub(/\sул[.,\s]+/, '')
                                                 .gsub(/\sзд[.,\s]+/, '')
                                                 .gsub(/\sстр[.,\s]+/, '')
                                                 .gsub(/,/, '')
                                                 .gsub(
                                                   /  /, ' '
                                                 )
          next if clear_address.blank?

          response = Osm.fetch(clear_address).parsed_response
          # response = \sHT[,.]\sTParty\sget("https://osm.kovalev.team/search.php?q=#{CGI.escape(clear_address)}").parsed_response

          csv << [
            organization['id'],
            organization['address'],
            clear_address,
            response.first ? response.first['lat'] : nil,
            response.first ? response.first['lon'] : nil
          ]
          dcsv << [
            organization['id'],
            response.first ? response.first['lat'] : nil,
            response.first ? response.first['lon'] : nil
          ]
          bar.increment!
          #   rescue StandardError
          #     csv << ['ERROR', organization['id']]
        end
      end
    end
  end

  def organizations
    @organizations ||= HTTParty.get('https://atom-api.kovalev.team/org/address').parsed_response
  end
end

class Osm
  include HTTParty
  persistent_connection_adapter
  base_uri 'localhost:8088'
  #   base_uri 'https://osm.kovalev.team'

  def self.fetch(q)
    q = CGI.escape(q)
    get("/search.php?q=#{q}")
  end
end

Address.new.perform
