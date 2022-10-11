# frozen_string_literal: true

require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::Operations::Transformers::Cv3ApplicationTo::IdentifySlcspRequest, type: :model, dbclean: :after_each do
  describe '#call' do
    subject { described_class.new.call(mm_application) }

    context 'invalid mm_application input' do
      let(:mm_application) { { test: 'test' } }

      it 'should return a failure' do
        expect(subject.failure?).to be_truthy
      end
    end

    context 'valid input' do
      include_context 'cms ME simple_scenarios test_case_d'

      let(:member_dob) { Date.new(current_date.year - 12, current_date.month, current_date.day) }
      let(:person) { FactoryBot.create(:person, :with_consumer_role, first_name: 'Gerald', last_name: 'Rivers', dob: member_dob) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:application) { FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "submitted", family_id: family.id, effective_date: TimeKeeper.date_of_record) }
      let(:mm_application) { ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success }

      before do
        person.update_attributes!(hbx_id: '95')
      end

      it 'should return success result' do
        expect(subject.success?).to be_truthy
        expect(subject.success[0]).to eq(family)
      end
    end
  end
end

