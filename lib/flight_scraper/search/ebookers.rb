require 'mechanize'

class FlightScraper::Search::Ebookers
  def initialize(segments)
    @segments = segments
    @agent = Mechanize.new
  end

  def execute
    submit_search_form
    interpret_search_results
  end

  def submit_search_form
    @agent.get("http://www.ebookers.de")
    @agent.click("Gabelflüge / Mehrere Stopps")

    search_form = @agent.page.form_with(:class => "searchFormForm")

    @segments.each_with_index do |segment, i|
      search_form.field_with(:name => /slc\[#{i}\]\.orig\.key/).value = segment.from
      search_form.field_with(:name => /slc\[#{i}\]\.dest\.key/).value = segment.to
      search_form.field_with(:name => /slc\[#{i}\]\.date/).value = segment.date.strftime("%d.%m.%Y")
    end

    search_form.submit(search_form.button_with(:name => "search"))
  end

  def interpret_search_results
    @agent.page.search(".airResultsCard").map do |result_card|
      build_result(result_card)
    end
  end

  def build_result(result_card)
    money = result_card.search(".basePrice .money").text
    flights = result_card.search("li").text.tr("\n\t", "").squeeze(" ")
    price_data = money.match /^(\d+),(\d+)(.*)$/
    raise "Could not match data" unless price_data
    {
      price: price_data[1].to_i,
      currency: price_data[3],
      flights: flights
    }
  end

end
