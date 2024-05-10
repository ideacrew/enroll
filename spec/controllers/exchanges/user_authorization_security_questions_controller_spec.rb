# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::SecurityQuestionsController, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }

  before do
    allow(Settings.aca).to receive_message_chain('security_questions').and_return(true)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.index?, (Pundit policy)')
      end
    end
  end

  describe 'GET #new' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.new?, (Pundit policy)')
      end
    end
  end

  describe 'POST #create' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        post :create, params: {}
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.create?, (Pundit policy)')
      end
    end
  end

  describe 'GET #edit' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        get :edit, params: { id: 'random_id' }
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.edit?, (Pundit policy)')
      end
    end
  end

  describe 'PATCH #update' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        patch :update, params: { id: 'random_id' }
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.update?, (Pundit policy)')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'security questions feature is disabled' do
      it 'redirects to root with flash message' do
        delete :destroy, params: { id: 'random_id' }
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('Access not allowed for security_question_policy.destroy?, (Pundit policy)')
      end
    end
  end
end
