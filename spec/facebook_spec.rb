# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/facebook'

RSpec.describe 'Getting events from Facebook' do
  let(:facebook) do
    Facebook.new(
      username: ENV.fetch('FACEBOOK_USERNAME'),
      password: ENV.fetch('FACEBOOK_PASSWORD')
    )
  end

  it 'can log into Facebook' do
    facebook.login!
    expect(facebook.logged_in?).to be_truthy
  end

  it 'can find a list of events' do
    facebook.login!
    expect(facebook.events(id: 'TheChurchNightclub', limit: 1).size).to eq 1
  end

  it 'can find an events information' do
    facebook.login!
    event = facebook.event(link: 'https://www.facebook.com/events/387742325019480/')
    expect(event).to eq(
      date: Time.parse('2018-01-26 21:00:00.000000000 -0700'),
      description: "Global Dance presents Ritual Fridays\nft. 4B\n\nTickets on sale now: http://bit.ly/4B-Church18\n\nMain Stage\n1230-Close 4B\n1130-1230- Ecotek\n1030-1130- RDP\n9-1030- Uptone\n\nBaSSment\n1-145 Skuby\n12-1- Lexi Fey\n11-12- Digital Virus\n10-11- Seamus\n9-10 Squid\n\nAt 24 years old, DJ and producer Bobby McKeon know as “4B”; has already spent 11 years relentlessly pursuing his sound and vision. During this period, he’s garnered significant support from industry heavyweights such as Skrillex, Diplo, Tiesto, & DJ Snake. The support bleeds deep for the thriving producer; it is a special moment when world icon DJ Snake looks over to his peer Diplo and states that 4B is “the next big thing with the hottest s**t in the streets”.\n\nFollow Global Dance on socials\nTwitter/Instagram: @GlobalDanceUS\nSnapchat: @GlobalDanceFest\n\n\n1160 Lincoln Street. Denver, CO\nCall 303-619-9513 for bottle service\n18+ Admission. 21+ to drink.\nDoors open at 9:00pm",
      location: '1160 Lincoln St, Denver, Colorado 80203',
      title: 'Ritual Fridays: 4B',
      link: 'https://www.facebook.com/events/387742325019480/'
    )
  end
end
