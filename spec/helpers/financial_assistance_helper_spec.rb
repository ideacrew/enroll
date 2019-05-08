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
end
