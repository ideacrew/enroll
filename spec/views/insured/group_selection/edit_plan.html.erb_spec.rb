require "rails_helper"

# Our helper slug class so we can use the helper methods in our spec
module SpecHelperClassesForViews
  class InsuredFamiliesHelperSlugForGroupSelectionTermination
    extend Insured::FamiliesHelper
  end
end

RSpec.describe "app/views/insured/group_selection/edit_plan.html.erb" do
  context "Enrollment information and buttons" do
    let(:family) { FactoryBot.create(:individual_market_family) }
    let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
    let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, title: "AAA", sbc_document: sbc_document) }
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members, family: family, product: product) }

    before(:each) do
      family.special_enrollment_periods << sep
      coverage_household = family.active_household.coverage_households.first
      enrollment.rebuild_members_by_coverage_household(coverage_household: coverage_household)
      @self_term_or_cancel_form = ::Insured::Forms::SelfTermOrCancelForm.for_view({enrollment_id: enrollment.id, family_id: family.id})
      assign :self_term_or_cancel_form, @self_term_or_cancel_form
      assign :should_term_or_cancel, @self_term_or_cancel_form.enrollment.should_term_or_cancel_ivl
      assign :calendar_enabled, @should_term_or_cancel == 'cancel' ? false : true

      render :template =>"insured/group_selection/edit_plan.html.erb"
    end

    it "should show the DCHL ID as hbx_enrollment.hbx_id" do
      expect(rendered).to match(/ID/)
      expect(rendered).to match /#{enrollment.hbx_id}/
    end

    it "should show the correct Premium" do
      dollar_amount = number_to_currency(SpecHelperClassesForViews::InsuredFamiliesHelperSlugForGroupSelectionTermination.current_premium(enrollment), precision: 2)
      expect(rendered).to match /Premium/
      expect(rendered).to include dollar_amount
    end

    it "should show Cancel Plan button" do
      expect(rendered).to have_selector("a", text: "Cancel Plan",  count: 1)
    end

  end
end
