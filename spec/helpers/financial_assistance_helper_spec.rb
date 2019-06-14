require 'rails_helper'

RSpec.describe FinancialAssistanceHelper, :type => :helper, dbclean: :after_each do

  describe 'decode_msg' do
    let(:encoded_msg) {'101'}
    let(:wrong_encoded_msg) {'111'}

    context 'when correct message send for decode' do
      it 'should return decoded msg' do
        expect(helper.decode_msg(encoded_msg)).to eq 'faa.acdes_lookup'
      end
    end

    context 'when wrong message send for decode' do
      it 'should return nil' do
        expect(helper.decode_msg(wrong_encoded_msg)).to eq nil
      end
    end
  end

  describe 'applicant_name' do
    before :each do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:applicant) { FactoryGirl.create(:applicant, family_member_id: family.primary_applicant.id, application: application) }

    context 'when proper applicant id is sent' do
      it 'should match with the full name of the person' do
        expect(helper.applicant_name(applicant.id).to_s).to eq person.full_name
      end
    end

    context 'when wrong id is sent' do
      it 'should return nil' do
        expect(helper.applicant_name(nil)).to be_nil
      end
    end
  end

  describe 'format_phone' do
    context 'for invalid phone number' do
      it 'should return empty string' do
        expect(helper.format_phone("2763")).to eq ""
      end
    end

    context 'for valid phone number' do
      it 'should return the expected format' do
        expect(helper.format_phone("1234567890")).to eq "(123) 456-7890"
      end
    end
  end

  describe 'format_benefit_cost' do
    context 'for valid arguments' do
      it 'should return a valid string' do
        expect(helper.format_benefit_cost(100.12, 'daily')).to eq "$100.12 Daily"
      end
    end

    context 'for invalid arguments' do
      it 'should return empty string' do
        expect(helper.format_benefit_cost(nil, 'daily')).to eq ''
      end

      it 'should return empty string' do
        expect(helper.format_benefit_cost(100.13, nil)).to eq ''
      end
    end
  end

  describe 'redirection urls' do
    before :each do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    let!(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:applicant) { FactoryGirl.create(:applicant, family_member_id: family.primary_applicant.id, application: application) }
    let(:application_id) { application.id.to_s}
    let(:applicant_id) { applicant.id.to_s}

    describe 'deductions_next_url' do
      it 'should return other_questions index url for non_applicant' do
        person.consumer_role.update_attributes!(is_applying_coverage: false)
        expect(helper.deductions_next_url(application, applicant)).to eq "/financial_assistance/applications/#{application_id}/applicants/#{applicant_id}/other_questions"
      end

      it 'should return benefits index url for applicant' do
        expect(helper.deductions_next_url(application, applicant)).to eq "/financial_assistance/applications/#{application_id}/applicants/#{applicant_id}/benefits"
      end
    end

    describe 'other_questions_previous_url' do
      it 'should return deductions index url for non_applicant' do
        person.consumer_role.update_attributes!(is_applying_coverage: false)
        expect(helper.other_questions_previous_url(application, applicant)).to eq "/financial_assistance/applications/#{application_id}/applicants/#{applicant_id}/deductions"
      end

      it 'should return benefits index url for applicant' do
        expect(helper.other_questions_previous_url(application, applicant)).to eq "/financial_assistance/applications/#{application_id}/applicants/#{applicant_id}/benefits"
      end
    end
  end

  describe 'display_benefits' do
    let(:enr_benefit) { double(kind: 'is_enrolled', insurance_kind: 'acf_refugee_medical_assistance') }
    let(:eli_benefit) { double(kind: 'is_eligible', insurance_kind: 'acf_refugee_medical_assistance') }
    let(:applicant) { double(:has_hbx_staff_role? => true, :benefits => [enr_benefit, eli_benefit]) }

    before :each do
      allow(applicant).to receive(:enrolled_benefits).and_return([enr_benefit])
      allow(applicant).to receive(:eligible_benefits).and_return([eli_benefit])
    end

    context 'for matching kind and matching insurance_kind' do
      it 'should return array with matching eligible benefits' do
        matching_benefits = helper.display_benefits(applicant, 'is_eligible', "acf_refugee_medical_assistance")
        expect(matching_benefits).to eq [eli_benefit]
      end

      it 'should return array with matching enrolled benefits' do
        matching_benefits = helper.display_benefits(applicant, 'is_enrolled', "acf_refugee_medical_assistance")
        expect(matching_benefits).to eq [enr_benefit]
      end
    end

    context 'for matching kind and different insurance_kind' do
      it 'should return empty array' do
        matching_benefits = helper.display_benefits(applicant, 'is_eligible', "test")
        expect(matching_benefits).to eq []
      end

      it 'should return empty array' do
        matching_benefits = helper.display_benefits(applicant, 'is_enrolled', "test")
        expect(matching_benefits).to eq []
      end
    end
  end
end
