# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Locations::AddressesController, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  describe 'DELETE #destroy' do
    let(:user) { FactoryBot.create(:user, person: primary) }
    let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { primary.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary) }
    let(:primary_member) { family.primary_applicant }

    let(:application) do
      FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'draft')
    end

    let(:applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        :with_home_address,
        first_name: primary.first_name,
        last_name: primary.last_name,
        application: application,
        is_primary_applicant: true,
        family_member_id: primary_member.id,
        person_hbx_id: primary.hbx_id
      )
    end

    let(:address) do
      applicant.addresses.create(
        kind: 'mailing',
        address_1: '1234 Awesome Street NE',
        city: 'Washington',
        state: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
        zip: '01001',
        county: 'Hampden'
      )
    end

    before do
      consumer_role.move_identity_documents_to_verified
      sign_in(user)
      delete :destroy, params: input_params
    end

    context 'with:
      - valid application
      - valid applicant
      - valid address
      ' do

      let(:input_params) do
        { application_id: application.id.to_s, applicant_id: applicant.id.to_s, id: address_id }
      end

      let(:address_id) { address.id.to_s }

      it 'destroys the address and redirects back' do
        expect(applicant.reload.addresses.where(id: address_id).count).to be_zero
        expect(flash[:notice]).to eq('Address is successfully destroyed.')
        expect(response).to redirect_to(Rails.application.class.routes.url_helpers.root_path)
      end
    end

    context 'with:
      - valid application
      - valid applicant
      - invalid address
      ' do

      let(:input_params) do
        { application_id: application.id.to_s, applicant_id: applicant.id.to_s, id: 'address_id' }
      end

      it 'redirects back with an flash error' do
        expect(flash[:error]).to eq('Address not found with the given parameters.')
        expect(response).to redirect_to(Rails.application.class.routes.url_helpers.root_path)
      end
    end

    context 'with:
      - valid application
      - invalid applicant
      - valid address
      ' do

      let(:input_params) do
        { application_id: application.id.to_s, applicant_id: 'applicant_id', id: address.id.to_s }
      end

      it 'redirects back with an flash error' do
        expect(flash[:error]).to eq('Applicant not found with the given parameters.')
        expect(response).to redirect_to(Rails.application.class.routes.url_helpers.root_path)
      end
    end

    context 'with:
      - invalid application
      - valid applicant
      - valid address
      ' do

      let(:input_params) do
        { application_id: 'application_id', applicant_id: applicant.id.to_s, id: address.id.to_s }
      end

      it 'redirects back with an flash error' do
        expect(flash[:error]).to eq('Application not found with the given parameters.')
        expect(response).to redirect_to(Rails.application.class.routes.url_helpers.root_path)
      end
    end
  end
end
