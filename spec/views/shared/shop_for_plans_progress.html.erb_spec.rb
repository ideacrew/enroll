require 'rails_helper'

describe "shared/_shop_for_plans_progress.html.erb" do
  let(:plan) { FactoryGirl.build(:plan) }
  let(:enrollment) { double(id: 'hbx_id') }

  context "step 1" do
    before :each do
      assign :change_plan, "change"
      render 'shared/shop_for_plans_progress', step: '1'
    end

    it "should have li option for Plan Selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have 33% complete" do
      expect(rendered).to match /33%/
    end
  end

  context "step 2" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      render 'shared/shop_for_plans_progress', step: '2'
    end

    it "should have 66% complete" do
      expect(rendered).to match /66%/
    end

    it "should have li option for plan selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have purchase button" do
      expect(rendered).to have_selector('a', text: 'Purchase')
    end

    it "should have previous option" do
      expect(rendered).to match /PREVIOUS/
    end
  end
end
