# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::People::InitializeVlpDocument do
  describe '#call' do
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
       :addresses => [{:kind => "home", :address_1 => "test", :address_2 => "", :address_3 => "", :city => "test", :county => "Kennebec", :state => "ME", :zip => "04333", :country_name => ""}],
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

      it 'returns a vlp document hash' do
        expect(@result.success).to be_a(Entities::VlpDocument)
      end

      it 'returns a hash without person attributes' do
        hash = @result.success.to_h
        expect(hash).not_to have_key(:person_addresses)
        expect(hash).not_to have_key(:person_phones)
        expect(hash).not_to have_key(:person_emails)
        expect(hash).not_to have_key(:hbx_id)
        expect(hash).not_to have_key(:person_hbx_id)
      end

      it 'returns a hash without consumer role attributes' do
        hash = @result.success.to_h
        expect(hash).not_to have_key(:is_applicant)
        expect(hash).not_to have_key(:is_applying_coverage)
        expect(hash).not_to have_key(:citizen_status)
      end

      it 'returns a hash with vlp document attributes that are filled' do
        hash = @result.success.to_h
        expect(hash).to have_key(:subject)
        expect(hash).to have_key(:alien_number)
        expect(hash).to have_key(:card_number)
        expect(hash).to have_key(:expiration_date)
        expect(hash).not_to have_key(:sevis_id)
      end
    end

    context 'failure' do
      context 'when applicant params are not passed' do
        let(:applicant_params) { {} }

        before do
          @result = described_class.new.call(applicant_params)
        end

        it 'returns a success result' do
          expect(@result.success?).to be_truthy
        end

        it 'should not return failure message' do
          expect(@result.success.to_h).to eq({})
        end
      end
    end
  end
end