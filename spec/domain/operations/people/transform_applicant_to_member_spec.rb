# frozen_string_literal: true

require 'rails_helper'
require 'domain/operations/financial_assistance/applicant_params_context'

RSpec.describe Operations::People::TransformApplicantToMember, dbclean: :after_each do
  include_context 'export_applicant_attributes_context'

  let(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '20944967',
                      last_name: 'primary_last',
                      first_name: 'primary_first',
                      ssn: '243108282',
                      dob: Date.new(1984, 3, 8))
  end

  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

  describe '#call' do
    let(:params) do
      applicant_params.merge(family_id: family.id, relationship: 'spouse')
    end

    context 'success' do
      before do
        allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)

        @result = described_class.new.call(params)
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
        expect(member_hash[:consumer_role]).to have_key(:immigration_documents_attributes)
      end

      it 'returns a member hash with consumer role attributes' do
        member_hash = @result.success
        expect(member_hash).to have_key(:consumer_role)
        expect(member_hash[:consumer_role]).to have_key(:skip_consumer_role_callbacks)
        expect(member_hash[:consumer_role]).to have_key(:is_applicant)
        expect(member_hash[:consumer_role]).to have_key(:immigration_documents_attributes)
      end

      it 'returns a member hash with demographics group attributes' do
        member_hash = @result.success
        expect(member_hash).to have_key(:demographics_group)
        expect(member_hash[:demographics_group]).to have_key(:alive_status)
        expect(member_hash[:demographics_group][:alive_status]).to have_key(:is_deceased)
        expect(member_hash[:demographics_group][:alive_status]).to have_key(:date_of_death)
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