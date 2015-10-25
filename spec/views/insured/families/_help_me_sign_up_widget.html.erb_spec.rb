require 'rails_helper'

RSpec.describe "_help_me_sign_up_widget.html.erb_spec" do
  before :each do
    render "insured/families/help_me_sign_up_widget.html.erb_spec"
  end
  it "should have button with text 'Help Me Sign Up'" do
    expect(rendered).to have_content "Help Me Sign Up"
  end

  it "should have hidden help with plan shoppping modal" do
    expect(rendered).to have_selector("#help_with_plan_shopping")
  end
  debugger

end
