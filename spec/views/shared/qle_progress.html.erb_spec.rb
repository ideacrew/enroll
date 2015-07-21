require 'rails_helper'

describe "shared/_signup_progress.html.erb" do
  before :each do
    assign :change_plan, "change"
    render 'shared/qle_progress', locals: {step: '1'}
  end

  it "should have li option for Plan Selection" do
    expect(rendered).to have_selector("li", text: "Plan Selection")
  end

  it "should have li option for household" do
    expect(rendered).to have_selector("li", text: "Household")
  end
end
