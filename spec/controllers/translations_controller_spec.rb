# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TranslationsController, :type => :controller do
  let!(:super_admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: super_admin_person) }
  let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }
  let!(:super_admin_person) { FactoryBot.create(:person) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let!(:hbx_super_admin_staff_role) do
    HbxStaffRole.create!(person: super_admin_person, permission_id: super_admin_permission.id, subrole: super_admin_subrole, hbx_profile_id: hbx_profile.id)
  end
  let(:super_admin_subrole) { 'super_admin' }
  let!(:test_translation) { FactoryBot.build(:translation, id: "1") }
  let(:test_translation_id) { test_translation.id }

  before :each do
    sign_in(super_admin_user)
    allow(Translation).to receive(:find).with("1").and_return(test_translation)
  end

  context "Permissions" do
    context "#new" do
      context 'with a valid MIME type' do
        context "as a super admin" do
          it "should be authorized" do
            get :new
            expect(response.status).to be(200)
          end
        end

        context "as a non super admin user" do
          before do
            super_admin_permission.update_attributes!(name: "non_super_admin")
          end
          it "should not be authorized" do
            get :new
            expect(response).to_not eq(200)
          end
        end
      end

      context 'with an invalid MIME type' do
        it "js should not be authorized" do
          get :new, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should not be authorized" do
          get :new, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should not be authorized" do
          get :new, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    context "#create" do
      context "as a super admin" do
        # Passes locally but not on GH for some rason
        xit "should be authorized" do
          post :create, params: {translation: {key: "en.translation", value: "This is the translation."}}
          expect(response.status).to be(200)
        end
      end

      context "as a non super admin user" do
        before do
          super_admin_permission.update_attributes!(name: "non_super_admin")
        end
        it "should not be authorized" do
          post :create, params: {translation: {key: "en.translation", value: "This is the translation."}}
          expect(response).to_not eq(200)
        end
      end
    end

    context "#edit" do
      context 'with a valid MIME type' do
        context "as a super admin" do
          it "should be authorized" do
            get :edit, params: {id: test_translation.id}
            expect(response.status).to be(200)
          end
        end

        context "as a non super admin user" do
          before do
            super_admin_permission.update_attributes!(name: "non_super_admin")
          end
          it "should not be authorized" do
            get :edit, params: {id: test_translation.id}
            expect(response).to_not eq(200)
          end
        end
      end

      context 'with an invalid MIME type' do
        it "js should not be authorized" do
          get :edit, params: {id: test_translation.id}, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should not be authorized" do
          get :edit, params: {id: test_translation.id}, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should not be authorized" do
          get :edit, params: {id: test_translation.id}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    context "#update" do
      context "as a super admin" do
        xit "should be authorized" do
          put :update, params: {id: test_translation.id, translation: {key: "en.translation", value: "This is the translation."}}
          expect(response.status).to be(200)
        end
      end

      context "as a non super admin user" do
        before do
          super_admin_permission.update_attributes!(name: "non_super_admin")
        end
        it "should not be authorized" do
          put :update, params: {id: test_translation.id, translation: {key: "en.translation", value: "This is the translation."}}
          expect(response).to_not eq(200)
        end
      end
    end

    context "#show" do
      context 'with a valid MIME type' do
        context "as a super admin" do
          it "should be authorized" do
            get :show, params: {id: test_translation.id}
            expect(response.status).to be(200)
          end
        end

        context "as a non super admin user" do
          before do
            super_admin_permission.update_attributes!(name: "non_super_admin")
          end
          it "should not be authorized" do
            get :show, params: {id: test_translation.id}
            expect(response).to_not eq(200)
          end
        end
      end

      context 'with an invalid MIME type' do
        it "js should not be authorized" do
          get :show, params: {id: test_translation.id}, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should not be authorized" do
          get :show, params: {id: test_translation.id}, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should not be authorized" do
          get :show, params: {id: test_translation.id}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    context "#index" do
      context 'with a valid MIME type' do
        context "as a super admin" do
          it "should be authorized" do
            get :index
            expect(response.status).to be(200)
          end
        end

        context "as a non super admin user" do
          before do
            super_admin_permission.update_attributes!(name: "non_super_admin")
          end
          it "should not be authorized" do
            get :index
            expect(response).to_not eq(200)
          end
        end
      end

      context 'with an invalid MIME type' do
        it "js should not be authorized" do
          get :index, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should not be authorized" do
          get :index, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should not be authorized" do
          get :index, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end
  end
end
