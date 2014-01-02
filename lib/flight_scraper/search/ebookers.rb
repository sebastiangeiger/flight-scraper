require 'mechanize'

class FlightScraper::Search::Ebookers
  def initialize(segments, type = nil)
    @segments = segments
    @type = type.new if type
    @agent = Mechanize.new
  end

  def execute
    submit_search_form
    interpret_search_results
  end

  def type
    @type ||= SearchType.type_for(@segments)
  end

  def submit_search_form
    @agent.get("http://www.ebookers.de")
    @agent.click(type.label)

    search_form = @agent.page.form_with(:class => "searchFormForm")

    if type.is_a? OneWay or type.is_a? RoundTrip
      search_form.field_with(:name => /leaveSlice\.orig/).value = @segments[0].from
      search_form.field_with(:name => /leaveSlice\.dest/).value = @segments[0].to
      search_form.field_with(:name => /leaveSlice\.date/).value = @segments[0].date.strftime("%d.%m.%Y")
    end

    if type.is_a? RoundTrip
      search_form.field_with(:name => /returnSlice\.date/).value = @segments[1].date.strftime("%d.%m.%Y")
    end

    if type.is_a? Multiple
      @segments.each_with_index do |segment, i|
        search_form.field_with(:name => /slc\[#{i}\]\.orig\.key/).value = segment.from
        search_form.field_with(:name => /slc\[#{i}\]\.dest\.key/).value = segment.to
        search_form.field_with(:name => /slc\[#{i}\]\.date/).value = segment.date.strftime("%d.%m.%Y")
      end

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

  SearchType = Struct.new(:label) do
    def self.type_for(segments)
      [OneWay, RoundTrip, Multiple].select{|x| x.accepts(segments)}.first.new
    end
  end

  class OneWay < SearchType
    def initialize
      super "Nur Hinflug"
    end

    def self.accepts(segments)
      segments.length == 1
    end
  end

  class RoundTrip < SearchType
    def initialize
      super "Hin-/Rückflug"
    end

    def self.accepts(segments)
      segments.length == 2 and segments.first.from == segments.last.to and segments.first.to == segments.last.from
    end
  end

 class Multiple < SearchType
    def initialize
      super "Gabelflüge / Mehrere Stopps"
    end

    def self.accepts(segments)
      segments.length >= 2 and not RoundTrip.accepts(segments)
    end
  end


end

