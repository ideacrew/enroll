# frozen_string_literal: true

require "rails_helper"

RSpec.describe "insured/consumer_roles/search.html.erb" do

  let(:person) { FactoryBot.create(:person) }
  let(:current_user) { FactoryBot.create(:user, person: person) }

  before :each do
    sign_in current_user
    assign(:person, Forms::ConsumerCandidate.new)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render template: "insured/consumer_roles/search.html.erb"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h2', text: 'Personal Information')
  end

  it "should have the content enter your information" do
    expect(rendered).to have_selector('p', text: "Enter your personal information. When you're finished, select CONTINUE.")
  end

end
