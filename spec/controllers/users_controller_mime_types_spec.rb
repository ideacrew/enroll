# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end


  describe 'with authorization and authentication' do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:hbx_staff_role) { person.hbx_staff_role }
    let(:permission) { FactoryBot.create(:permission, :full_access_super_admin) }
    let(:admin) { FactoryBot.create(:user, person: person) }

    let(:user_person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, person: user_person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: user_person) }

    before do
      hbx_staff_role.update_attributes!(permission_id: permission.id)
      sign_in(admin)
    end

    describe 'GET #confirm_lock' do
      shared_examples 'responds_to_mime_type for GET endpoint confirm_lock' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :confirm_lock, params: { id: user.id, format: mime_type }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint confirm_lock', [:html, :json, :xml, :csv, :text]
    end

    describe 'GET #lockable' do
      shared_examples 'responds_to_mime_type for GET endpoint lockable' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :lockable, params: { id: user.id, format: mime_type }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint lockable', [:html, :json, :xml, :csv, :text]
    end

    describe 'GET #reset_password' do
      shared_examples 'responds_to_mime_type for GET endpoint reset_password' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :reset_password, params: { id: user.id, format: mime_type }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint reset_password', [:html, :json, :xml, :csv, :text]
    end

    describe 'PUT #confirm_reset_password' do
      shared_examples 'responds_to_mime_type for PUT endpoint confirm_reset_password' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            put :confirm_reset_password, params: { id: user.id, format: mime_type }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for PUT endpoint confirm_reset_password', [:html, :json, :xml, :csv, :text]
    end

    describe 'GET #change_username_and_email' do
      shared_examples 'responds_to_mime_type for GET endpoint change_username_and_email' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :change_username_and_email, params: {
              id: user.id,
              format: mime_type
            }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint change_username_and_email', [:html, :json, :xml, :csv, :text]
    end

    describe 'POST #confirm_change_username_and_email' do
      let(:person2) { FactoryBot.create(:person) }
      let(:user2) { FactoryBot.create(:user, person: person2) }

      shared_examples 'responds_to_mime_type for POST endpoint confirm_change_username_and_email' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            post :confirm_change_username_and_email, params: {
              id: user.id,
              family_actions_id: family.id,
              new_email: user2.email,
              new_oim_id: user2.oim_id,
              format: mime_type
            }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for POST endpoint confirm_change_username_and_email', [:html, :json, :xml, :csv, :text]
    end

    describe 'GET #login_history' do
      shared_examples 'responds_to_mime_type for GET endpoint login_history' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :login_history, params: {
              id: user.id,
              format: mime_type
            }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint login_history', [:html, :json, :xml, :csv, :text]
    end
  end

  describe 'without authorization and authentication' do

    describe 'GET #unsupported_browser' do
      shared_examples 'responds_to_mime_type for GET endpoint unsupported_browser' do |unsupported_mime_types|
        unsupported_mime_types.each do |mime_type|
          it "rejects #{mime_type}" do
            get :unsupported_browser, params: { format: mime_type }
            expect(response).to have_http_status(:not_acceptable)
          end
        end
      end

      include_examples 'responds_to_mime_type for GET endpoint unsupported_browser', [:js, :json, :xml, :csv, :text]
    end
  end
end
