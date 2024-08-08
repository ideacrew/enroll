# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::TimeKeeperController, dbclean: :around_each do
  let(:user)                { FactoryBot.create(:user) }

  context 'when user is admin with time travel permission' do
    let(:person)              { FactoryBot.create(:person, user: user) }
    let(:permission)          { FactoryBot.create(:permission, :super_admin, can_submit_time_travel_request: true, modify_admin_tabs: true) }
    let!(:hbx_staff_role)      { FactoryBot.create(:hbx_staff_role, person: person, permission_id: permission.id, subrole: permission.name) }

    before do
      allow(EnrollRegistry[:time_jump].feature).to receive(:is_enabled).and_return(true)
      sign_in user
    end

    describe 'GET #hop_to_date' do
      context 'with valid params' do
        let(:new_date) { TimeKeeper.date_of_record + 1.day }
        let(:params) { { date_of_record: new_date.strftime('%Y-%m-%d').to_s } }

        it 'advances the date of record to the new date' do
          get :hop_to_date, params: { forms_time_keeper: params }

          expect(response).to redirect_to(configuration_exchanges_hbx_profiles_path)
          expect(flash[:notice]).to eq("Time Hop is successful, Date is advanced to #{new_date.strftime('%m/%d/%Y')}")
        end
      end

      context 'with invalid params' do
        context 'when the new date is not a future date' do
          let(:new_date) { TimeKeeper.date_of_record - 1.day }
          let(:params) { { date_of_record: new_date.to_s } }

          it 'returns failure message' do
            get :hop_to_date, params: { forms_time_keeper: params }

            expect(response).to redirect_to(configuration_exchanges_hbx_profiles_path)
            expect(flash[:error]).to eq('Invalid date, please select a future date')
          end
        end

        context 'when the new date is not a valid date' do
          let(:new_date) { 'invalid date' }
          let(:params) { { date_of_record: new_date } }

          it 'returns failure message' do
            get :hop_to_date, params: { forms_time_keeper: params }

            expect(response).to redirect_to(configuration_exchanges_hbx_profiles_path)
            expect(flash[:error]).to eq('Unable to parse date, please enter a valid date')
          end
        end
      end
    end
  end

  context 'when user is admin with time travel permission' do
    let(:person)              { FactoryBot.create(:person, user: user) }
    let(:permission)          { FactoryBot.create(:permission, :super_admin, can_submit_time_travel_request: false, modify_admin_tabs: true) }
    let!(:hbx_staff_role)      { FactoryBot.create(:hbx_staff_role, person: person, permission_id: permission.id, subrole: permission.name) }
    before do
      allow(EnrollRegistry[:time_jump].feature).to receive(:is_enabled).and_return(true)
      sign_in user
    end

    describe 'GET #hop_to_date' do
      context 'with valid params' do
        let(:new_date) { TimeKeeper.date_of_record + 1.day }
        let(:params) { { date_of_record: new_date.strftime('%Y-%m-%d').to_s } }

        it 'advances the date of record to the new date' do
          get :hop_to_date, params: { forms_time_keeper: params }

          expect(response.status).to eq 406
        end
      end
    end
  end

  context 'when user is not admin' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, user: user) }

    before do
      sign_in user
    end

    describe 'GET #hop_to_date' do
      it 'returns unauthorized' do
        get :hop_to_date

        expect(response.status).to eq 406
      end
    end
  end
end