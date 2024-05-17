require 'rails_helper'

describe "shared/_sep_shop_for_plans_progress.html.haml" do
  let(:plan) { FactoryBot.build(:plan) }
  let(:enrollment) { double(id: 'hbx_id') }
  let(:person) { FactoryBot.create(:person)}

  context "step 1" do
    before :each do
      assign :change_plan, "change"
      render 'shared/sep_shop_for_plans_progress', step: '1'
    end

    it "should have li option for Plan Selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have 33% complete" do
      expect(rendered).to match /33% Complete/
    end
  end

  context "step 2" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      allow(person).to receive(:consumer_role).and_return(false)
      @person = person
      render 'shared/sep_shop_for_plans_progress', step: '2'
    end

    it "should have 66% complete" do
      expect(rendered).to match /66% Complete/
    end

    it "should have li option for plan selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

  end

  context "step 3" do
    before :each do
      assign :change_plan, "change_plan"
      assign :plan, plan
      assign :enrollment, enrollment
      assign :enrollment_kind, "sep"
      allow(person).to receive(:consumer_role).and_return(false)
      @person = person
      render 'shared/sep_shop_for_plans_progress', step: '3'
    end

    it "should have 85% complete" do
      expect(rendered).to match(/85%/)
    end

    it "should have confirm button" do
      expect(rendered).to have_selector('a', text: /Confirm/)
    end

    it "should have previous option" do
      expect(rendered).to match /PREVIOUS/i
    end
  end

  context "step 4" do
    before :each do
      assign :change_plan, "change_plan"
      assign :plan, plan
      assign :enrollment, enrollment
      assign :enrollment_kind, "sep"
      allow(person).to receive(:consumer_role).and_return(false)
      @person = person
      render 'shared/sep_shop_for_plans_progress', step: '4'
    end

    it "should have 100% complete" do
      expect(rendered).to match(/100% Complete/)
    end

    it "should have link to family home page" do
      expect(rendered).to have_selector('a[href="/families/home"]')
    end

  end
end
