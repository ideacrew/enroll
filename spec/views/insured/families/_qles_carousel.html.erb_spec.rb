require 'rails_helper'

RSpec.describe "insured/families/_qles_carousel.html.erb" do
  before :each do
    QualifyingLifeEventKind.delete_all
    10.times.each {FactoryGirl.create(:qualifying_life_event_kind)}
    FactoryGirl.create(:qualifying_life_event_kind, tool_tip: "")
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    render "insured/families/qles_carousel"
  end

  it "should have carousel-qles area" do
    expect(rendered).to have_selector('div#carousel-qles')
  end

  it "should have qle options" do
    QualifyingLifeEventKind.all.each do |qle|
      expect(rendered).to have_selector('a.qle-menu-item', text: qle.title.humanize)
    end
  end

  it "should have carousel-indicators" do
    expect(rendered).to have_selector('ol.carousel-indicators')
  end

  it "should have carousel-control" do
    expect(rendered).to have_selector('a.carousel-control', count: 2)
  end

  it "should have placement bottom options" do
    expect(rendered).to have_selector("a.qle-menu-item[data-placement='bottom']")
    expect(rendered).to have_selector("a.qle-menu-item[data-placement='top']")
  end

  it "should not have tooltip when tool_tip is blank" do
    expect(rendered).to have_selector("a.qle-menu-item[data-toggle='tooltip']", count: 10)
    expect(rendered).to have_selector("a.qle-menu-item", count: 11)
  end
end
