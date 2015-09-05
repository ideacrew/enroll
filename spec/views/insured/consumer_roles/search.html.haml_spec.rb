require "rails_helper"

RSpec.describe "insured/consumer_roles/search.html.haml" do
  before :each do
    assign(:person, Forms::ConsumerCandidate.new)

    render template: "insured/consumer_roles/search.html.haml"
  end

  it "should display title" do
    expect(rendered).to have_selector('h3', text: 'Personal Information')
  end

  it "should have memo to indicate required fields" do
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end
end
