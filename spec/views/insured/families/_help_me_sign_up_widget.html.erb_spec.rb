require 'rails_helper'

RSpec.describe "_help_signup.html.erb" do
  before :each do
    render "insured/families/help_signup"
  end
  it "should have button with text 'Help Me Sign Up'" do
    expect(rendered).to have_content "Help Me Sign Up"
  end

end
