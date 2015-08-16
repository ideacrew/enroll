require 'rails_helper'

RSpec.describe "consumer_profiles/_qles_carousel.html.erb" do
  before :each do
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    render "consumer_profiles/qles_carousel"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h3', text: 'Have Life Events?')
    expect(rendered).to have_selector('small', text: 'See how it may affect your health insurance.')
    expect(rendered).to have_selector('h5', text: 'TOP LIFE CHANGES')
  end

  it "should have carousel" do
    expect(rendered).to have_selector('div#carousel-qles')
    expect(rendered).to have_selector('div.carousel-inner')
    expect(rendered).to have_selector('ol.carousel-indicators')
    expect(rendered).to have_selector('a.carousel-control', count: 2)
  end

  it "should have qle options" do
    QualifyingLifeEventKind.all.each do |qle|
      expect(rendered).to have_selector('a.qle-menu-item', text: qle.title.humanize)
    end
  end

  it "should have hidden qle details" do
    expect(rendered).to have_selector('div.hidden#qle-details')
  end

  it "should have image" do
    expect(rendered).to have_selector('img[alt="Life event"]')
  end
end
