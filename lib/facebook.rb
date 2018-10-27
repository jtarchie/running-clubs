require 'capybara/dsl'
require 'capybara/sessionkeeper'
require 'chronic'
require 'logger'

class Facebook
  include Capybara::DSL

  def initialize(username:, password:)
    @username = username
    @password = password
    Capybara.current_driver = :selenium_chrome_headless
  end

  def login!
    visit 'https://facebook.com/'
    if File.exist?('cookies.txt')
      page.restore_cookies('cookies.txt')
      visit 'https://facebook.com'
    end

    return if logged_in?

    visit 'https://facebook.com/login'
    fill_in 'email', with: @username
    fill_in 'pass',  with: @password
    click_button 'loginbutton'
    page.save_cookies('cookies.txt')
  end

  def logged_in?
    visit 'https://facebook.com'
    !page.all('input[name="q"]').empty?
  end

  def events(id:, limit: 0)
    visit "https://facebook.com/#{id}/events"
    page.has_no_css?('#page-events-tab-loading-spinner', wait: 10)

    upcoming_events = page.all('#upcoming_events_card a[href*="ref_page_id"]')
    upcoming_events = upcoming_events.select do |link|
      (link[:href] || '').include?('/events')
    end
    upcoming_events = upcoming_events[0..limit - 1] if limit > 0

    upcoming_events.map do |link|
      url = URI.parse(link[:href])
      "#{url.scheme}://#{url.host}#{url.path}"
    end.compact.map do |link|
      event(link: link)
    end
  end

  def event(link:)
    logger.info "visiting even site #{link}"
    visit link
    date = begin
             node = page.find('#event_time_info div[content]')
             time = node.text.split(',')[1..-1].join(' ')
             time = time.split(/[–-]/)[0]

             Chronic.parse(time)
           rescue StandardError
             logger.error 'could not find a date'
             nil
           end
    title = begin
              page.find('#title_subtitle [data-testid*="event-permalink-event-name"]').text
            rescue StandardError
              logger.error 'could not find a title'
              nil
            end
    description = begin
                    page.find('#reaction_units [data-testid*="event-permalink-details"]').text
                  rescue StandardError
                    logger.error 'could not find a description'
                    nil
                  end
    location = begin
                 page.find('#event_summary a + div', text: /\d{5}/).text
               rescue StandardError
                 logger.error 'could not find a location'
                 nil
               end
    {
      date: date,
      title: title,
      description: description,
      location: location
    }
  end

  private

  def logger
    @logger ||= Logger.new(STDERR)
  end
end
