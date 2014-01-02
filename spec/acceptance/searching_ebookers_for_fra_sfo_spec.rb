require_relative '../../lib/flight_scraper'
require_relative '../spec_helper'

describe 'Searching for a oneway from FRA to SFO yields 45 results', :vcr do
  it 'returns 45 oneway results' do

    segments = [FlightScraper::Segment.new("FRA", "SFO", Date.new(2014,2,15))]

    results = FlightScraper::Search::Ebookers.new(segments).execute

    results.size.should == 45
    results.first.should have_key :price
    results.sort{|a,b| a[:price] <=> b[:price]}.first[:price].should == 1135
    results.map{|r| r[:currency]}.uniq.should == ["€"]
  end
end

describe 'Searching for a roundtrip from FRA to SFO yields 45 results', :vcr do
  it 'returns 45 roundtrip results' do

    segments = [FlightScraper::Segment.new("FRA", "SFO", Date.new(2014,2,15)),
                FlightScraper::Segment.new("SFO", "FRA", Date.new(2014,2,25))]

    results = FlightScraper::Search::Ebookers.new(segments).execute

    results.size.should == 45
    results.first.should have_key :price
    results.sort{|a,b| a[:price] <=> b[:price]}.first[:price].should == 572
    results.map{|r| r[:currency]}.uniq.should == ["€"]
  end
end

describe 'Searching for FRA-EWR-SFO-MUC yields 45 results', :vcr do
  it 'returns 45 roundtrip results' do

    segments = [FlightScraper::Segment.new("FRA", "EWR", Date.new(2014,2,15)),
                FlightScraper::Segment.new("EWR", "SFO", Date.new(2014,2,25)),
                FlightScraper::Segment.new("SFO", "MUC", Date.new(2014,2,28))]

    results = FlightScraper::Search::Ebookers.new(segments).execute

    results.size.should == 45
    results.first.should have_key :price
    results.sort{|a,b| a[:price] <=> b[:price]}.first[:price].should == 723
    results.map{|r| r[:currency]}.uniq.should == ["€"]
  end
end

describe 'Searching multileg is the same as', :vcr do
  it '... searching roundtrip' do
    segments = [FlightScraper::Segment.new("FRA", "SFO", Date.new(2014,2,15)),
                FlightScraper::Segment.new("SFO", "FRA", Date.new(2014,2,25))]
    round_trip = FlightScraper::Search::Ebookers.new(segments).execute
    multi_leg = FlightScraper::Search::Ebookers.new(segments, FlightScraper::Search::Ebookers::Multiple).execute
    round_trip.should == multi_leg
  end
  it '... searching oneway' do
    segments = [FlightScraper::Segment.new("FRA", "SFO", Date.new(2014,2,15))]
    one_way = FlightScraper::Search::Ebookers.new(segments).execute
    multi_leg = FlightScraper::Search::Ebookers.new(segments, FlightScraper::Search::Ebookers::Multiple).execute
    one_way.should == multi_leg
  end
end
