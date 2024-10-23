# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::FinancialAssistance::ApplicationHelper, :type => :helper, dbclean: :after_each do
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new) }
  let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      eligibility_determination_id: ed.id,
                      is_ia_eligible: true,
                      is_claimed_as_tax_dependent: false,
                      is_required_to_file_taxes: true,
                      first_name: 'Test',
                      last_name: 'Test10')
  end

  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      eligibility_determination_id: ed.id,
                      is_ia_eligible: true,
                      is_claimed_as_tax_dependent: true,
                      first_name: 'TEst2',
                      last_name: 'Test10')
  end

  describe 'claim_eligible_tax_dependents' do
    let!(:applicant3) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        eligibility_determination_id: ed.id,
                        is_ia_eligible: true,
                        is_claimed_as_tax_dependent: true,
                        first_name: 'TEst3',
                        last_name: 'Test10')
    end

    it "doesn't include is_claimed_as_tax_dependent true applicants (applicant 2)" do
      assign(:application, application)
      assign(:applicant, applicant3)
      expect(helper.claim_eligible_tax_dependents.map(&:first).flatten).to_not include("TEst2 Test10")
    end
  end

  describe 'total_aptc_across_eligibility_determinations' do
    before do
      @result = helper.total_aptc_across_eligibility_determinations(application.id)
    end

    it 'should return the sum of all aptcs' do
      expect(@result).to eq(225.13)
    end
  end

  describe 'eligible_applicants' do
    before do
      @result = helper.eligible_applicants(application.id, :is_ia_eligible)
    end

    it 'should return array of names of the applicants' do
      expect(@result).to include('Test Test10')
    end

    it 'should not return a split name if multiple capital letters exist' do
      expect(@result).to include('Test2 Test10')
    end
  end

  describe 'any_csr_ineligible_applicants?' do
    before do
      @result = helper.any_csr_ineligible_applicants?(application.id)
    end

    it 'should return false as the only applicant is eligible for CSR' do
      expect(@result).to be_falsy
    end
  end

  describe 'applicant_currently_enrolled' do
    context 'text for non hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(true)
        @result = helper.applicant_currently_enrolled
      end

      it 'should return non hra text' do
        expect(@result).to include('Is this person currently enrolled in health coverage?')
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_currently_enrolled
      end

      it 'should return hra text' do
        expect(@result).to include('Is this person currently enrolled in health coverage or getting help paying for health coverage through a Health Reimbursement Arrangement?')
      end
    end

    context 'When both the settings are turned off' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(false)
        @result = helper.applicant_currently_enrolled
      end

      it 'should return nil' do
        expect(@result).to eq ''
      end
    end
  end

  describe 'applicant_currently_enrolled_key' do
    context 'text for non hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(true)
        @result = helper.applicant_currently_enrolled_key
      end

      it 'should return non hra key' do
        expect(@result).to eq 'has_enrolled_health_coverage'
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_currently_enrolled_key
      end

      it 'should return hra key' do
        expect(@result).to eq 'has_enrolled_health_coverage_from_hra'
      end
    end

    context 'When both the settings are turned off' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(false)
        @result = helper.applicant_currently_enrolled_key
      end

      it 'should return nil' do
        expect(@result).to eq ''
      end
    end
  end

  describe 'applicant_eligibly_enrolled' do
    context 'text for non hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(true)
        @result = helper.applicant_eligibly_enrolled
      end

      it 'should return non hra text' do
        expect(@result).to include('Does this person currently have access to other health coverage that they are not enrolled in, including coverage they could get through another person?')
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_eligibly_enrolled
      end

      it 'should return hra text' do
        expect(@result).to include('Does this person currently have access to health coverage or a Health Reimbursement Arrangement that they are not enrolled in (including through another person, like a spouse or parent)?')
      end
    end

    context 'text for hra setting is turned on and minimum_value_standard_question enabled' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:minimum_value_standard_question).and_return(true)
        @result = helper.applicant_eligibly_enrolled
      end

      it 'should return hra text without the parentheses' do
        expect(@result).to include('Does this person currently have access to health coverage or a Health Reimbursement Arrangement that they are not enrolled in?')
      end
    end

    context 'When both the settings are turned off' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(false)
        @result = helper.applicant_eligibly_enrolled
      end

      it 'should return nil' do
        expect(@result).to eq ''
      end
    end
  end

  describe 'applicant_eligibly_enrolled_key' do
    context 'text for non hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(true)
        @result = helper.applicant_eligibly_enrolled_key
      end

      it 'should return non hra key' do
        expect(@result).to eq 'has_eligible_health_coverage'
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_eligibly_enrolled_key
      end

      it 'should return hra key' do
        expect(@result).to eq 'has_eligible_health_coverage_from_hra'
      end
    end

    context 'When both the settings are turned off' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(false)
        @result = helper.applicant_eligibly_enrolled_key
      end

      it 'should return nil when both the settings are turned off' do
        expect(@result).to eq ''
      end
    end
  end

  context 'csr_73_87_or_94_eligible_applicants' do
    before do
      applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: [73, 87, 94].sample })
      applicant.reload
      @result = helper.csr_73_87_or_94_eligible_applicants?(application.id)
    end

    it "should return applicant's full name" do
      expect(@result).to include(applicant.full_name)
    end
  end

  context 'csr_100_eligible_applicants' do
    before do
      applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: 100 })
      applicant.reload
      @result = helper.csr_100_eligible_applicants?(application.id)
    end

    it "should return applicant's full name" do
      expect(@result).to include(applicant.full_name)
    end
  end

  context 'csr_limited_eligible_applicants' do
    context 'aqhp' do
      before do
        applicant.update_attributes!({ is_ia_eligible: true, csr_percent_as_integer: -1 })
        applicant.reload
        @result = helper.csr_limited_eligible_applicants?(application.id)
      end

      it "should return applicant's full name" do
        expect(@result).to include(applicant.full_name)
      end
    end

    context 'uqhp' do
      before do
        applicant.update_attributes!({ indian_tribe_member: true })
        applicant.reload
        @result = helper.csr_limited_eligible_applicants?(application.id)
      end

      it "should return applicant's full name" do
        expect(@result).to include(applicant.full_name)
      end
    end
  end

  context '#fetch_counties_by_zip', dbclean: :after_each do
    let!(:county) {BenefitMarkets::Locations::CountyZip.create(zip: "04642", county_name: "Hancock")}

    context 'for 9 digit zip' do
      it "should return county" do
        applicant.addresses.create(zip: "04642-3116", county: 'Hancock', state: 'ME')
        address = applicant.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq ['Hancock']
      end
    end

    context 'for 5 digit zip' do
      it "should return county" do
        applicant.addresses.create(zip: "04642", county: 'Hancock', state: 'ME')
        address = applicant.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq ['Hancock']
      end
    end

    context 'for nil address' do
      it "should return empty array" do
        result = helper.fetch_counties_by_zip(nil)
        expect(result).to eq []
      end
    end

    context 'for nil zip' do
      it "should return empty array" do
        applicant.addresses.update_all(zip: nil, county: 'Hancock')
        address = applicant.addresses.first
        result = helper.fetch_counties_by_zip(address)
        expect(result).to eq []
      end
    end
  end

  describe '#full_name' do
    it 'should return name' do
      expect(helper.full_name(applicant)).to eq('Test Test10')
    end
  end

  describe '#display_csr' do
    context 'csr eligible for 94, 87, 73, 100' do
      let(:csr_kind) { ['csr_94', 'csr_87', 'csr_73', 'csr_100'].sample }

      it 'should return displayable csr' do
        applicant.csr_eligibility_kind = csr_kind
        applicant.save!
        expect(helper.display_csr(applicant.reload)).to eq("#{csr_kind.split('_').last}%")
      end
    end

    context 'csr_limited' do
      it 'should return displayable csr' do
        applicant.csr_eligibility_kind = 'csr_limited'
        applicant.save!
        expect(helper.display_csr(applicant.reload)).to eq('Limited')
      end
    end
  end

  describe '#prospective_year_application?' do
    let(:system_year) { TimeKeeper.date_of_record.year }
    let(:application_stub) { OpenStruct.new(assistance_year: application_year) }
    let(:current_user) { OpenStruct.new(has_hbx_staff_role?: false) }
    let(:current_hbx_profile) { OpenStruct.new(under_open_enrollment?: open_enrollment) }

    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:block_prospective_year_application_copy_before_oe).and_return(enabled)
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_profile)
    end

    context 'configuration is turned OFF' do
      let(:enabled) { false }
      let(:open_enrollment) { false }
      let(:application_year) { system_year }

      it 'should return false as feature is turned OFF' do
        expect(helper.prospective_year_application?(application_stub)).to eq(false)
      end
    end

    context 'configuration is turned ON and is under open_enrollment' do
      let(:enabled) { true }
      let(:open_enrollment) { true }
      let(:application_year) { system_year }

      it 'should return false as system is under open_enrollment' do
        expect(helper.prospective_year_application?(application_stub)).to eq(false)
      end
    end

    context 'configuration turned ON, not under open_enrollment, prospective_year_application' do
      let(:enabled) { true }
      let(:open_enrollment) { false }
      let(:application_year) { system_year.next }

      it 'should return false as system is under open_enrollment' do
        expect(helper.prospective_year_application?(application_stub)).to eq(true)
      end
    end

    context 'configuration turned ON, under open_enrollment, current_year_application' do
      let(:enabled) { true }
      let(:open_enrollment) { true }
      let(:application_year) { system_year }

      it 'should return false as system is under open_enrollment' do
        expect(helper.prospective_year_application?(application_stub)).to eq(false)
      end
    end

    context 'configuration turned ON, not under open_enrollment, application without application_year' do
      let(:enabled) { true }
      let(:open_enrollment) { false }
      let(:application_year) { nil }

      it 'should return false as system is under open_enrollment' do
        expect(helper.prospective_year_application?(application_stub)).to eq(false)
      end
    end
  end

  describe '#display_minimum_value_standard_question?' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:minimum_value_standard_question).and_return(enabled)
    end

    context 'RR configuration turned OFF' do
      let(:enabled) { false }
      let(:insurance_kind) { 'health_reimbursement_arrangement' }

      it 'should return false' do
        expect(
          helper.display_minimum_value_standard_question?(insurance_kind)
        ).to eq(false)
      end
    end

    context 'RR configuration turned ON, insurance_kind: health_reimbursement_arrangement' do
      let(:enabled) { true }
      let(:insurance_kind) { 'health_reimbursement_arrangement' }

      it 'should return false' do
        expect(
          helper.display_minimum_value_standard_question?(insurance_kind)
        ).to eq(false)
      end
    end

    context 'RR configuration turned ON, insurance_kind: employer_sponsored_insurance' do
      let(:enabled) { true }
      let(:insurance_kind) { 'employer_sponsored_insurance' }

      it 'should return true' do
        expect(
          helper.display_minimum_value_standard_question?(insurance_kind)
        ).to eq(true)
      end
    end
  end

  describe '#display_esi_fields?' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:short_enrolled_esi_forms).and_return(enabled)
    end

    context 'RR configuration turned OFF' do
      let(:enabled) { false }
      let(:insurance_kind) { 'health_reimbursement_arrangement' }

      it 'should return true if enrolled' do
        expect(
          helper.display_esi_fields?(insurance_kind, 'is_enrolled')
        ).to eq(true)
      end

      it 'should return true if eligible' do
        expect(
          helper.display_esi_fields?(insurance_kind, 'is_eligible')
        ).to eq(true)
      end
    end

    context 'RR configuration turned ON' do
      let(:enabled) { true }
      let(:insurance_kind) { 'employer_sponsored_insurance' }

      it 'should return false if enrolled' do
        expect(
          helper.display_esi_fields?(insurance_kind, 'is_enrolled')
        ).to eq(false)
      end

      it 'should return true if eligible' do
        expect(
          helper.display_esi_fields?(insurance_kind, 'is_eligible')
        ).to eq(true)
      end
    end
  end
end
