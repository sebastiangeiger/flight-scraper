require 'mechanize'

class FlightScraper::Search::Ebookers
  def initialize(segment)
    @segment = segment
    @type = :one_way
    @agent = Mechanize.new
  end
  def execute
    submit_search_form
    interpret_search_results
  end

  def submit_search_form
    @agent.get("http://www.ebookers.de")
    if @type == :one_way
      @agent.click("Nur Hinflug")
    else
      raise "idiot"
    end
    search_form = @agent.page.form_with(:class => "searchFormForm")
    search_form.field_with(:name => /leaveSlice\.orig/).value = @segment.from
    search_form.field_with(:name => /leaveSlice\.dest/).value = @segment.to
    search_form.field_with(:name => /leaveSlice\.date/).value = @segment.date.strftime("%d.%m.%Y")
    search_form.submit(search_form.button_with(:name => "search"))
  end

  def interpret_search_results
    @agent.page.search(".airResultsCard").map do |result_card|
      build_result(result_card)
    end
  end

  def build_result(result_card)
    money = result_card.search(".basePrice .money").text
    match_data = money.match /^(\d+),(\d+)(.*)$/
    raise "Could not match" unless match_data
    {
      price: match_data[1].to_i,
      currency: match_data[3]
    }
  end
end

