# frozen_string_literal: true

require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe HbxAdminHelper, :type => :helper do
    let(:family)    { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:primary_fm) {family.primary_applicant}
    let(:household) { FactoryBot.create(:household, family: family)}
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        title: 'IVL Test Plan Silver',
                        benefit_market_kind: :aca_individual,
                        kind: 'health',
                        deductible: 2000,
                        metal_level_kind: 'silver',
                        csr_variant_id: '01',
                        issuer_profile: issuer_profile)
    end

    let(:hbx) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              product: product,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              kind: 'individual',
                              changing: false,
                              effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days),
                              applied_aptc_amount: 100)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    let(:hbx_inactive) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              product: product,
                              is_active: false,
                              aasm_state: 'coverage_terminated',
                              kind: 'individual',
                              changing: false,
                              effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days),
                              applied_aptc_amount: 100)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    let(:hbx_without_aptc) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              product: product,
                              is_active: true,
                              aasm_state: 'coverage_selected',
                              kind: 'individual',
                              changing: false,
                              effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days),
                              applied_aptc_amount: 0)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    context "#active_eligibility?" do
      let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household) }

      it "should return yes" do
        tax_household.update_attributes!(effective_ending_on: nil)
        expect(helper.active_eligibility?(family)).to eq 'Yes'
      end

      it "should return no" do
        expect(helper.active_eligibility?(family)).to eq 'No'
      end
    end
  end
end
