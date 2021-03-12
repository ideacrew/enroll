require 'rails_helper'

RSpec.describe "insured/families/_qles_carousel.html.erb" do
  before :each do
    QualifyingLifeEventKind.delete_all
    10.times.each {FactoryBot.create(:qualifying_life_event_kind)}
    FactoryBot.create(:qualifying_life_event_kind, tool_tip: "")
    assign(:person, FactoryBot.create(:person))
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
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
    expect(rendered).to have_selector("a[data-is-self-attested='true']")
  end

  it "shouldn't display Employee button for person without multiple roles" do
    expect(rendered).not_to match(/Employee/)
  end

  it "shouldn't display Individual button for person without multiple roles" do
    expect(rendered).not_to match(/Individual/)
  end

  it "should not have links blocked" do
    expect(rendered).not_to have_selector('.blocking')
  end

  context "QLE buttons for person with both roles" do
    before :each do
      assign(:multiroles, true)
      EnrollRegistry[:aca_shop_market].feature.stub(:is_enabled).and_return(true)
    end

    it "contain buttons group for QLE roles" do
      render "insured/families/qles_carousel"
      expect(rendered).to have_selector('div.market-selection')
    end

    it "should have Employee button for person with multiple roles" do
      allow(view).to receive(:individual_market_is_enabled?).and_return(true)
      render "insured/families/qles_carousel"
      expect(rendered).to have_link('Employee')
      expect(rendered).to have_link('Individual')
    end

    it "should not display Individual button if Individual market is disabled" do
      allow(view).to receive(:individual_market_is_enabled?).and_return(false)
      render "insured/families/qles_carousel"
      expect(rendered).not_to match(/Individual/)
      expect(rendered).to have_link('Employee')
    end
  end

end
