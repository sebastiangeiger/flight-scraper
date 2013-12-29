require_relative '../../lib/flight_scraper'
require 'pry'
require 'launchy'

describe 'Searching for a flight from FRA to SFO yields some results' do
  it 'returns 45 results' do
    segment = FlightScraper::Segment.new("FRA", "SFO", Date.new(2014,2,15))
    results = FlightScraper::Search.new(segment).execute
    results.size.should == 45
    results.first.should have_key :price
    results.sort{|a,b| a[:price] <=> b[:price]}.first[:price].should == 1135
    results.map{|r| r[:currency]}.uniq.should == ["€"]
  end
end
