require 'rails_helper'

RSpec.describe "insured/families/_effective_on_kind_fields.html.erb" do
  let(:qlk) {FactoryGirl.create(:qualifying_life_event_kind)}
  let(:effective_on_options) {[TimeKeeper.date_of_record, TimeKeeper.date_of_record - 1.month]}
  before :each do
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    assign :qle, qlk
    assign :qle_date, TimeKeeper.date_of_record
    assign :effective_on_options, effective_on_options
  end

  it "should show hidden field" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event'])
    render "insured/families/effective_on_kind_fields"
    expect(rendered).to have_selector('input#effective_on_kind')
  end

  it "should have select" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', "first_of_next_month"])
    render "insured/families/effective_on_kind_fields"
    expect(rendered).to have_selector('select#effective_on_kind')
  end

  it "should have effective_on_kind select" do
    render "insured/families/effective_on_kind_fields"
    expect(rendered).to have_selector('select#effective_on_date')
  end

  it "should have effective_on_kind select options" do
    render "insured/families/effective_on_kind_fields"
    effective_on_options.each do |date|
      expect(rendered).to have_selector("option[value='#{date.to_s}']")
    end
    expect(rendered).to have_selector('select#effective_on_date')
  end

  context "when I've had a baby" do
    before :each do
      assign :qle_date, TimeKeeper.date_of_record
      allow(qlk).to receive(:title).and_return("I've had a baby")
      allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', 'fixed_first_of_next_month'])
      render "insured/families/effective_on_kind_fields"
    end

    it "should have effective_on_kind options with date" do
      expect(rendered).to have_selector('select#effective_on_date')
      expect(rendered).to have_selector("option", text: "Date of event(#{TimeKeeper.date_of_record.to_s})")
      expect(rendered).to have_selector("option", text: "Fixed first of next month(#{(TimeKeeper.date_of_record.end_of_month + 1.day).to_s})")
    end

    it "should have qle_effective_on_kind_alert area" do
      expect(rendered).to match /Please Select effective on kind/
    end
  end

  context "when I've adopted a child" do
    before :each do
      assign :qle_date, TimeKeeper.date_of_record
      allow(qlk).to receive(:title).and_return("I've adopted a child")
      allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', 'fixed_first_of_next_month'])
      render "insured/families/effective_on_kind_fields"
    end

    it "should have effective_on_kind options with date" do
      expect(rendered).to have_selector('select#effective_on_date')
      expect(rendered).to have_selector("option", text: "Date of event(#{TimeKeeper.date_of_record.to_s})")
      expect(rendered).to have_selector("option", text: "Fixed first of next month(#{(TimeKeeper.date_of_record.end_of_month + 1.day).to_s})")
    end

    it "should have qle_effective_on_kind_alert area" do
      expect(rendered).to match /Please Select effective on kind/
    end
  end

  context "when I Losing Employer-Subsidized Insurance because employee is going on Medicare" do

    before :each do
      assign :qle_date, TimeKeeper.date_of_record + 1.month
      assign :effective_on_options, [1, 2]
      
      allow(qlk).to receive(:title).and_return("when I Losing Employer-Subsidized Insurance because employee is going on Medicare")

      render "insured/families/effective_on_kind_fields"
    end

    it "should have qle message" do
      qle_date = TimeKeeper.date_of_record + 1.month
      expect(rendered).to match /Because your other health insurance is ending/
      expect(rendered).to match /#{qle_date.beginning_of_month}/
      expect(rendered).to match /#{(qle_date + 1.month).beginning_of_month}/
      expect(rendered).to match /#{qle_date.beginning_of_month - 1.day}/
    end

  end
end
