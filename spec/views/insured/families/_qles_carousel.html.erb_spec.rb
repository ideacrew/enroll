require 'rails_helper'

RSpec.describe "insured/families/_qles_carousel.html.erb" do
  before :each do
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    render "insured/families/qles_carousel"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h4 strong', text: 'Have Life Changes?')
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

  it "should have image" do
    expect(rendered).to have_selector('img[alt="Life event"]')
  end
end
