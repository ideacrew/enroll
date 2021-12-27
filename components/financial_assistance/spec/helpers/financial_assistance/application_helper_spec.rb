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
        expect(@result).to eq 'Is this person currently enrolled in health coverage? *'
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_currently_enrolled
      end

      it 'should return hra text' do
        expect(@result).to eq 'Is this person currently enrolled in health coverage or getting help paying for health coverage through a Health Reimbursement Arrangement? *'
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
        expect(@result).to eq 'Does this person currently have access to other health coverage that they are not enrolled in, including coverage they could get through another person? *'
      end
    end

    context 'text for hra setting is turned on' do
      before do
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(false)
        allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible_with_hra)).to receive(:item).and_return(true)
        @result = helper.applicant_eligibly_enrolled
      end

      it 'should return hra text' do
        expect(@result).to eq 'Does this person currently have access to health coverage or a Health Reimbursement Arrangement that they are not enrolled in (including through another person, like a spouse or parent)? *'
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
end
