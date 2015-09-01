require 'rails_helper'

RSpec.describe "consumer_profiles/_effective_on_kind_fields.html.erb" do
  let(:qlk) {FactoryGirl.create(:qualifying_life_event_kind)}
  let(:effective_on_options) {[TimeKeeper.date_of_record, TimeKeeper.date_of_record - 1.month]}
  before :each do
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    assign :qle, qlk
    assign :effective_on_options, effective_on_options
  end

  it "should show hidden field" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event'])
    render "consumer_profiles/effective_on_kind_fields"
    expect(rendered).to have_selector('input#effective_on_kind')
  end

  it "should have select" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', "first_of_next_month"])
    render "consumer_profiles/effective_on_kind_fields"
    expect(rendered).to have_selector('select#effective_on_kind')
  end

  it "should have effective_on_kind select" do
    render "consumer_profiles/effective_on_kind_fields"
    expect(rendered).to have_selector('select#effective_on_date')
  end

  it "should have effective_on_kind select options" do
    render "consumer_profiles/effective_on_kind_fields"
    effective_on_options.each do |date|
      expect(rendered).to have_selector("option[value='#{date.to_s}']")
    end
    expect(rendered).to have_selector('select#effective_on_date')
  end
end
