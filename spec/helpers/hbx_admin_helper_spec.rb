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

  context "APTC Enrollments:" do
    it "returns a full name of a person given person_id" do
      expect(helper.full_name_of_person(family.person)).to eq family.person.full_name
    end

    it "returns the ehb rounded to two decimal places" do
      expect(helper.ehb_percent_for_enrollment(hbx.id)).to eq 99.43
    end

    it "returns the applied_aptc percent for an enrollment" do
      expect(helper.find_applied_aptc_percent(hbx.applied_aptc_amount, 214.00).to_i).to eq 47
    end

    context "returns the correct class for td styling for current and past " do
      let(:past_month) { TimeKeeper.date_of_record.month == 1 ? 1 : TimeKeeper.date_of_record.month - 1 }
      let(:current_month) {TimeKeeper.date_of_record.month}
      let(:current_year) {TimeKeeper.date_of_record.year}

      it "returns the past-aptc-csr-data class for past_month" do
        if TimeKeeper.date_of_record.month == 1
          expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[past_month])).to eq "current-aptc-csr-data"
        else
          expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[past_month])).to eq "past-aptc-csr-data"
        end
      end

      it "returns the current-aptc-csr-data class for current_month" do
        expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[current_month])).to eq "current-aptc-csr-data"
      end
    end

    context "returns inactive enrollments" do
      it "returns all cancelled and terminated enrollments" do
        expect(helper.inactive_enrollments(family, TimeKeeper.date_of_record.year)).to be_an_instance_of Mongoid::Criteria
        expect(helper.inactive_enrollments(family, TimeKeeper.date_of_record.year).selector["aasm_state"]["$in"]).to include("coverage_canceled", "coverage_terminated")
      end
    end
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

  context "#max_aptc_that_can_be_applied_for_this_enrollment?" do
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:benefit_sponsorship) {double("benefit sponsorship", earliest_effective_date: TimeKeeper.date_of_record.beginning_of_year)}
    let!(:current_hbx) {double("current hbx", benefit_sponsorship: benefit_sponsorship, under_open_enrollment?: true)}
    let!(:tax_household) { FactoryBot.create(:tax_household, household: family.active_household) }
    let!(:tax_household_member) { tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: family.family_members[0].id) }
    let!(:ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household)}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let!(:tax_household11) { FactoryBot.create(:tax_household, household: family.active_household) }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.today.beginning_of_month + 14.days)
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}.update_attributes!(slcsp_id: product.id)
    end

    after do
      allow(TimeKeeper).to receive(:date_of_record).and_call_original
    end

    it "should not return zero" do
      tax_household.update_attributes!(effective_ending_on: nil)
      expect(helper.max_aptc_that_can_be_applied_for_this_enrollment(hbx.id)).not_to eq 0
    end
  end
end
end
