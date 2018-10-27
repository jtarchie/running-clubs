require 'capybara/dsl'
require 'capybara/sessionkeeper'
require 'logger'
require 'spec_helper'
require 'yaml'
require 'chronic'

RSpec.describe 'Getting events from Facebook' do
  include Capybara::DSL

  let(:logger) { Logger.new(STDERR) }

  before do
    Capybara.current_driver = :selenium_chrome_headless
  end

  after do
    page.save_cookies('cookies.txt')
  end

  it 'can log into Facebook' do
    logger.info 'visiting facebook.com'

    visit 'https://facebook.com'
    if File.exist?('cookies.txt')
      page.restore_cookies('cookies.txt')
      visit 'https://facebook.com'
    end

    if page.all('input[name="q"]').empty?
      logger.info 'could not find #q, logging in'

      visit 'https://facebook.com/login'
      fill_in 'email', with: ENV.fetch('FACEBOOK_USERNAME')
      fill_in 'pass',  with: ENV.fetch('FACEBOOK_PASSWORD')
      click_button 'loginbutton'
    end

    id = 'lookoutmountainrunners'
    visit "https://facebook.com/#{id}/events"
    expect(page).not_to have_css('#page-events-tab-loading-spinner')

    upcoming_events = page.all('#upcoming_events_card a[href*="ref_page_id"]')
    upcoming_events.map do |link|
      next unless (link[:href] || '').include?('/events')

      url = URI.parse(link[:href])
      "#{url.scheme}://#{url.host}#{url.path}"
    end.compact.each do |link|
      logger.info "visiting even site #{link}"
      visit link
      date = begin
               Chronic.parse(page.find('#event_time_info div[content]').text.split(',')[1..-1].join(' '))
             rescue StandardError
               nil
             end
      title = begin
                page.find('#title_subtitle [data-testid*="event-permalink-event-name"]').text
              rescue StandardError
                nil
              end
      description = begin
                  page.find('#reaction_units [data-testid*="event-permalink-details"]').text
                rescue StandardError
                  nil
                end
      location = begin
                   page.find('#event_summary a + div', text: /\d{5}/).text
                 rescue StandardError
                   nil
                 end
      puts({
        date: date,
        title: title,
        description: description,
        location: location
      }.to_yaml)
    end
  end
end
