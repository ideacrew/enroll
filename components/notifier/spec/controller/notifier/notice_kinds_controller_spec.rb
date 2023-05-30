# frozen_string_literal: true

require 'rails_helper'

# spec for notice kinds controller
module Notifier
  RSpec.describe NoticeKindsController, type: :controller, dbclean: :after_each do

    routes { Notifier::Engine.routes }

    let(:user) { FactoryBot.create(:user, :hbx_staff, person: FactoryBot.create(:person))}
    let!(:staff_role) do
      staff = user.person.hbx_staff_role
      staff.permission_id = permission.id
      staff.save
    end
    let(:permission) { FactoryBot.create(:permission, :super_admin, can_view_notice_templates: can_view_notice_templates, can_edit_notice_templates: can_edit_notice_templates)}

    describe '#index' do

      before do
        sign_in user
        get :index
      end

      context 'without permissions' do
        let(:can_view_notice_templates) { false }
        let(:can_edit_notice_templates) { false }

        it 'returns an error' do
          expect(flash[:error]).to eq "You are not authorized to perform this action."
        end
      end

      context 'with permissions' do
        let(:can_view_notice_templates) { true }
        let(:can_edit_notice_templates) { true }

        it 'returns success' do
          expect(flash[:error]).to eq nil
          expect(response).to be_success
        end
      end
    end

    describe '#edit' do
      let(:notice_kind) do
        ::Notifier::NoticeKind.create("title" => "title", "aasm_state" => "draft", "description" => "description", "event_name" => "evene", "market_kind" => :aca_shop, "notice_number" => "number", "recipient" => "recipient")
      end
      # let(:notice_kind) { FactoryBot.create(:notifier_notice_kind) }
      before do
        sign_in user
        get :edit, params: { id: notice_kind.id }, format: :js
      end

      context 'without permissions' do
        let(:can_view_notice_templates) { false }
        let(:can_edit_notice_templates) { false }

        it 'returns an error' do
          expect(flash[:error]).to eq "You are not authorized to perform this action."
        end
      end

      context 'with permissions' do
        let(:can_view_notice_templates) { true }
        let(:can_edit_notice_templates) { true }

        it 'returns success' do
          expect(flash[:error]).to eq nil
          expect(response).to be_success
        end
      end
    end
  end
end
