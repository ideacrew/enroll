# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferResponse, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
  end

  let(:transfer_id) { "tr123" }

  context 'success' do
    context 'with valid application id' do
      let(:person) { FactoryBot.create(:person)}
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}

      before do
        family.primary_person.emails.create(kind: "home", address: "fakeemail@email.com")
        @application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: family.id)
        @applicant = FactoryBot.create(:applicant, application: @application, person_hbx_id: person.hbx_id, transfer_referral_reason: 'Initiated')
        @expected_response =
          {
            family_identifier: family.hbx_assigned_id.to_s,
            application_identifier: @application.hbx_id,
            result: "Success"
          }
      end

      it 'should return success' do
        result = subject.call(@application.id)
        expect(result).to be_success
      end

      it 'should return success with message' do
        result = subject.call(@application.id)
        expect(result.value!).to eq(@expected_response)
      end

      context 'when account_transfer_notice_trigger is enabled' do
        before do
          allow(::EnrollRegistry).to receive(:feature_enabled?).with(:account_transfer_notice_trigger).and_return(true)
        end

        it 'should trigger account transfer notice' do
          expect(::Operations::Notices::IvlAccountTransferNotice).to receive_message_chain('new.call').with(family: family)
          subject.call(@application.id)
        end

        context 'when the family has already received the notice' do
          before do
            family.primary_person.inbox.messages.create(subject: 'Find Out If You Qualify For Health Insurance On CoverME.gov')
          end

          it 'should not receive duplicate account transfer notice' do
            expect(::Operations::Notices::IvlAccountTransferNotice).not_to receive(:new)
            subject.call(@application.id)
          end
        end
      end

      context 'when no applicants are initiated' do
        before do
          @applicant.transfer_referral_reason = "Rejected"
          @applicant.save!
        end

        it 'should not trigger account transfer notice' do
          expect(::Operations::Notices::IvlAccountTransferNotice).not_to receive(:new)
          subject.call(@application.id)
        end
      end

      context 'when account_transfer_notice_trigger is disabled' do
        before do
          allow(::EnrollRegistry).to receive(:feature_enabled?).with(:account_transfer_notice_trigger).and_return(false)
        end

        it 'should not trigger account transfer notice' do
          expect(::Operations::Notices::IvlAccountTransferNotice).not_to receive(:new)
          subject.call(@application.id)
        end
      end
    end
  end

  context 'failure' do
    context 'with missing application' do
      before do
        @result = subject.call(transfer_id)
      end

      it 'should return failure' do
        expect(@result).not_to be_success
      end

      it 'should return expected error message' do
        expect(@result.failure).to eq("Unable to find Application by ID.")
      end
    end

    context 'with missing family' do
      before do
        @application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: "missing")
        @result = subject.call(@application.id)
      end

      it 'should return failure' do
        expect(@result).not_to be_success
      end

      it 'should return expected error message' do
        expect(@result.failure).to eq("Unable to find Family with ID #{@application.family_id}.")
      end
    end
  end
end