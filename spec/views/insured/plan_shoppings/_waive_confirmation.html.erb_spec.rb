require 'rails_helper'

RSpec.describe "insured/plan_shoppings/_waive_confirmation.html.erb" do
  context "when not waivable" do
    before :each do
      assign(:waivable, false)
      render "insured/plan_shoppings/waive_confirmation"
    end

    it "should not display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end

    it "should display the reason coverage cannot be waived" do
      expect(rendered).to have_selector('h4', text: /Unable to Waive Coverage/)
    end
  end

  context "when waivable" do
    before :each do
      assign(:waivable, true)
      render "insured/plan_shoppings/waive_confirmation", enrollment: instance_double("HbxEnrollment", id: "enrollment_id")
    end

    it "should prompt for the waiver reason" do
      expect(rendered).to have_selector('h4', text: /Select Waive Reason/)
    end
  end
end
