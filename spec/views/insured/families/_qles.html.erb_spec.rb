require 'rails_helper'

RSpec.describe "insured/families/_qles.html.erb" do
  before :each do
    10.times.each {FactoryGirl.create(:qualifying_life_event_kind)}
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    render "insured/families/qles"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h4', text: 'TOP LIFE CHANGES')
  end

  it "should have list-qle area" do
    expect(rendered).to have_selector('ul.list-qle')
  end

  it "should have qle options" do
    QualifyingLifeEventKind.all.each do |qle|
      expect(rendered).to have_selector('a.qle-menu-item', text: qle.title.humanize)
    end
  end

  it "should have qle-details" do
    expect(rendered).to have_selector('div#qle-details.hidden')
  end
end
