# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::People::TransformApplicantToMember do
  let(:applicant) { FactoryBot.create(:applicant) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, primary_family_member: applicant) }

  describe '#call' do
    context 'when the applicant is already a member' do
      let(:current_date) { Date.today}
      let(:dob) { current_date - 20.years }
      let(:applicant_params) do
        {:first_name => "test",
         :middle_name => nil,
         :last_name => "test",
         :ssn => "564654900",
         :gender => "male",
         :dob => dob.to_s,
         :family_member_id => BSON::ObjectId('6525f616f78542bc66d12319'),
         :person_hbx_id => "169698664415129",
         :is_incarcerated => true,
         :ethnicity => ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"],
         :indian_tribe_member => false,
         :tribal_id => nil,
         :tribal_state => nil,
         :tribal_name => nil,
         :tribe_codes => [],
         :no_dc_address => false,
         :is_homeless => false,
         :no_ssn => "0",
         :citizen_status => "alien_lawfully_present",
         :is_consumer_role => true,
         :same_with_primary => false,
         :is_applying_coverage => true,
         :vlp_subject => "I-766 (Employment Authorization Card)",
         :alien_number => "745896592",
         :card_number => "4578451236592",
         :expiration_date => current_date + 1.year,
         :relationship => "child",
         :addresses => [{:kind => "home", :address_1 => "123dsas", :address_2 => "", :address_3 => "", :city => "Washisdfsd", :county => "Kennebec", :state => "ME", :zip => "04333", :country_name => ""}],
         :emails => [],
         :phones => [],
         :is_primary_applicant => false,
         :skip_consumer_role_callbacks => true,
         :skip_person_updated_event_callback => true}
      end


      context 'success' do
        before do
          @result = described_class.new.call(applicant_params)
        end

        it 'returns a success result' do

          expect(@result.success?).to be_truthy
        end

        it 'returns a member hash' do
          expect(@result.success).to be_a(Hash)
        end

        it 'returns a member hash with person attributes' do
          member_hash = @result.success
          expect(member_hash).to have_key(:person_addresses)
          expect(member_hash).to have_key(:person_phones)
          expect(member_hash).to have_key(:person_emails)
          expect(member_hash).to have_key(:hbx_id)
          expect(member_hash).not_to have_key(:person_hbx_id)
        end

        it 'returns a member hash with consumer role attributes' do
          member_hash = @result.success
          expect(member_hash).to have_key(:consumer_role)
          expect(member_hash[:consumer_role]).to have_key(:skip_consumer_role_callbacks)
          expect(member_hash[:consumer_role]).to have_key(:is_applicant)
          expect(member_hash[:consumer_role]).to have_key(:vlp_documents_attributes)
        end
      end

      context 'failure' do
        context 'when applicant params are not passed' do
          let(:applicant_params) { {} }

          before do
            @result = described_class.new.call(applicant_params)
          end

          it 'returns a failure result' do
            expect(@result.failure?).to be_truthy
          end

          it 'returns a failure message' do
            expect(@result.failure).to eq('Provide applicant_params for transformation')
          end
        end
      end
    end
  end
end