require 'rails_helper'

RSpec.describe "insured/families/_enrollment_progress.html.erb" do
  before :each do
    render partial: "insured/families/enrollment_progress", locals: {step: 2}
  end

  it "should display step name" do
    ["Applied", "Sent to Carrier", "Enrolled"].each do |step|
      expect(rendered).to match /#{step}/
    end
  end

  it "should display percent_complete" do
    expect(rendered).to have_selector("label", text:"66% Complete")
  end

  it "should display title" do
    expect(rendered).to have_selector('h4', text: 'Status')
  end
end
