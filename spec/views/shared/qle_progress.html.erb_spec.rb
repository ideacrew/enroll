require 'rails_helper'

describe "shared/_qle_progress.html.erb" do
  let(:plan) { FactoryGirl.build(:plan) }
  let(:enrollment) { double(id: 'hbx_id') }

  context "step 1" do
    before :each do
      assign :change_plan, "change"
      render 'shared/qle_progress', step: '1'
    end

    it "should have li option for Plan Selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have li option for household" do
      expect(rendered).to have_selector("li", text: "Household")
    end

    it "should have 25% complete" do
      expect(rendered).to match /25%/
    end
  end

  context "step 3" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      render 'shared/qle_progress', step: '3'
    end

    it "should have 75% complete" do
      expect(rendered).to match /75%/
    end

    it "should have li option for household" do
      expect(rendered).to have_selector("li", text: "Household")
    end

    it "should have purchase button" do
      expect(rendered).to have_selector('a', text: 'Purchase')
    end

    it "should have previous option" do
      expect(rendered).to match /PREVIOUS/
    end
  end
end
