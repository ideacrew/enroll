# frozen_string_literal: true

require 'rails_helper'

describe "shared/_shop_for_plans_progress.html.erb" do
  let(:plan) { FactoryBot.build(:plan) }
  let(:enrollment) { double(id: 'hbx_id') }
  let(:person) { FactoryBot.create(:person)}

  context "step 1" do
    before :each do
      assign :change_plan, "change"
      render 'shared/shop_for_plans_progress', step: '1'
    end

    it "should have li option for Plan Selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have 33% complete" do
      expect(rendered).to match(/33%/)
    end
  end

  context "step 2" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      allow(person).to receive(:consumer_role).and_return(false)
      allow(enrollment).to receive(:is_shop?).and_return(true)
      @person = person
      render 'shared/shop_for_plans_progress', step: '2'
    end

    it "should have 66% complete" do
      expect(rendered).to match(/66%/)
    end

    it "should have li option for plan selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have purchase button" do
      expect(rendered).to have_selector('a', text: 'Confirm')
    end

    it "should have previous option" do
      expect(rendered).to match(/PREVIOUS/i)
    end
  end

  context "step 2 - Confirm Button" do

    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      @person = person
    end

    it "should have confirm button initially disabled for IVL" do
      allow(enrollment).to receive(:is_shop?).and_return(false)
      render 'shared/shop_for_plans_progress', step: '2'
      expect(rendered).to have_selector('#btn-continue.disabled')
    end

    it "should have confirm button styling not disabled for shop " do
      allow(enrollment).to receive(:is_shop?).and_return(true)
      render 'shared/shop_for_plans_progress', step: '2'
      expect(rendered).not_to have_selector('#btn-continue.disabled')
    end

  end

  context "waive button with employee role" do
    let(:employee_role) {FactoryBot.build(:employee_role)}
    before :each do
      allow(enrollment).to receive(:employee_role).and_return employee_role
      assign :enrollment, enrollment
    end

    it "should show waive coverage link" do
      render 'shared/shop_for_plans_progress', step: '1', show_waive: true
      expect(rendered).to have_selector('a', text: 'Waive Coverage')
    end

    it "should not show waive coverage link" do
      render 'shared/shop_for_plans_progress', step: '1'
      expect(rendered).not_to have_selector('a', text: 'Waive Coverage')
    end
  end

  context "waive button without employee role" do
    let(:employee_role) {FactoryBot.build(:employee_role)}
    let(:benefit_group) {double("Benefit group")}
    before :each do
      allow(enrollment).to receive(:employee_role).and_return nil
      allow(enrollment).to receive(:benefit_group).and_return benefit_group
      assign :enrollment, enrollment
    end

    it "should show waive coverage link" do
      render 'shared/shop_for_plans_progress', step: '1', show_waive: true
      expect(rendered).to have_selector('a', text: 'Waive Coverage')
    end

    it "should not show waive coverage link" do
      render 'shared/shop_for_plans_progress', step: '1'
      expect(rendered).not_to have_selector('a', text: 'Waive Coverage')
    end
  end

  context "step 3" do
    let(:c_role) { true }
    let(:is_shop) { false }
    let(:market_kind) { 'individual' }

    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      assign :market_kind, market_kind
      allow(person).to receive(:consumer_role).and_return(c_role)
      allow(enrollment).to receive(:is_shop?).and_return(is_shop)
      @person = person
      render 'shared/shop_for_plans_progress', step: '3'
    end

    context 'when IVL' do
      it "should have go to my account text" do
        expect(rendered).to match(/#{l10n("insured.plan_shoppings.receipt.go_to_my_account")}/)
      end
    end

    context 'when SHOP' do
      let(:market_kind) { 'shop' }
      let(:c_role) { false }
      let(:is_shop) { true }

      it "should have CONTINUE text" do
        expect(rendered).to match(/#{l10n('continue').upcase}/)
      end
    end
  end
end
