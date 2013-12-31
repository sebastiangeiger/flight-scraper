require 'mechanize'

class FlightScraper::Search::Ebookers
  def initialize(segments)
    @segments = segments
    @type = get_trip_type
    @agent = Mechanize.new
  end

  def execute
    submit_search_form
    interpret_search_results
  end

  def submit_search_form
    @agent.get("http://www.ebookers.de")
    if @type == :oneway
      @agent.click("Nur Hinflug")
    elsif @type == :roundtrip
      @agent.click("Hin-/Rückflug")
    else
      raise "idiot"
    end

    #ar.rt.leaveSlice.orig.key
    #ar.rt.leaveSlice.dest.key
    #ar.rt.leaveSlice.date
    #ar.rt.returnSlice.date

    search_form = @agent.page.form_with(:class => "searchFormForm")
    search_form.field_with(:name => /leaveSlice\.orig/).value = @segments[0].from
    search_form.field_with(:name => /leaveSlice\.dest/).value = @segments[0].to
    search_form.field_with(:name => /leaveSlice\.date/).value = @segments[0].date.strftime("%d.%m.%Y")

    if @type == :roundtrip
      search_form.field_with(:name => /returnSlice\.date/).value = @segments[1].date.strftime("%d.%m.%Y")
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
    match_data = money.match /^(\d+),(\d+)(.*)$/
    raise "Could not match" unless match_data
    {
      price: match_data[1].to_i,
      currency: match_data[3]
    }
  end

  def get_trip_type

    if @segments.length == 1
      return :oneway 
    elsif @segments.length == 2 and @segments.first.from == @segments.last.to and @segments.first.to == @segments.last.from
      return :roundtrip 
    else
      return :multiple
    end

  end

end

