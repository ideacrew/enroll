# frozen_string_literal: true

require 'rails_helper'

# Update the SecurityQuestionPolicy to properly handle access permissions when the feature is enabled.
if SecurityQuestionPolicy.new('user', 'SecurityQuestion').index?
  RSpec.describe Exchanges::SecurityQuestionsController, dbclean: :after_each do

    let(:user) { FactoryBot.create(:user, with_security_questions: false) }
    let(:person) { FactoryBot.create(:person, user: user) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person) }
    let(:question) { instance_double("SecurityQuestion", title: 'Your Question', id: '1') }

    before :each do
      allow(Settings.aca).to receive_message_chain('security_questions').and_return(true)
      allow(user).to receive(:has_hbx_staff_role?).and_return true

      allow(SecurityQuestion).to receive(:all).and_return([question])
      allow(SecurityQuestion).to receive(:find).with(question.id).and_return(question)
      sign_in user
    end

    describe 'GET index' do
      before { get :index }
      it { expect(assigns(:questions)).to eq([question]) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/index') }
    end

    describe 'GET new' do
      before { get :new }
      it { expect(assigns(:question)).to be_a(SecurityQuestion) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/new') }
    end

    describe 'POST create' do
      context 'When create a question with invalid params' do
        before { post :create, params: {security_question: { title: nil } } }
        it { expect(assigns(:question).title).to be_empty }
        it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
        it { expect(response).to have_http_status(:success) }
        it { expect(response).to render_template('exchanges/security_questions/new') }
      end

      context 'When question is created successfully' do
        before { post :create, params: {security_question: { title: 'First Question' } } }
        it { expect(assigns(:question)).to be_a(SecurityQuestion) }
        it { expect(SecurityQuestion.all).not_to eq([]) }
        it { expect(assigns(:question).title).to eq('First Question') }
        it { expect(response).to redirect_to('/exchanges/security_questions') }
      end
    end

    describe 'GET edit' do
      before { get :edit, params: {id: question.id } }
      it { expect(assigns(:question)).to eq(question) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/edit') }
    end

    describe 'PUT update' do
      let(:true_if_allowed) { true }
      let(:title) { 'Updated title' }
      let(:params) {{ title: title } }
      let(:nil_params) {{ title: "" } }
      let(:strong_params){ActionController::Parameters.new(params).permit(:title)}
      let(:strong_nil_params){ActionController::Parameters.new(nil_params).permit(:title)}

      before do
        allow(question).to receive(:safe_to_edit_or_delete?).and_return(true_if_allowed)
        allow(question).to receive(:update_attributes).with(strong_params).and_return(true)
        allow(question).to receive(:title).and_return(title)
        put :update, params: {id: question.id, security_question: strong_params }
      end

      context 'When update question with valid title' do
        it { expect(assigns(:question)).to eq(question) }
        it { expect(assigns(:question).title).to eq(title) }
        it { expect(response).to redirect_to('/exchanges/security_questions') }
      end

      context "when updating a question that has been answered already" do
        let!(:true_if_allowed) { false }

        it { expect(assigns(:question)).to eq(question) }
        it { expect(response).to have_http_status(:success) }
        it { expect(response).to render_template('exchanges/security_questions/edit') }
      end

      context 'When update question with blank title' do
        let(:errors) { double(:errors, full_messages: ["Title can't be blank"]) }
        before do
          allow(question).to receive(:errors).and_return(errors)
          allow(question).to receive(:update_attributes).with(strong_nil_params).and_return(false)
          put :update,params: {id: question.id, security_question: strong_nil_params}
        end
        it { expect(assigns(:question)).to eq(question) }
        it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
        it { expect(response).to have_http_status(:success) }
        it { expect(response).to render_template('exchanges/security_questions/edit') }
      end
    end

    describe 'DELETE destroy' do
      let(:true_if_allowed) { true }
      let(:this_many) { 1 }
      before do
        allow(question).to receive(:safe_to_edit_or_delete?).and_return(true_if_allowed)
        expect(question).to receive(:destroy).exactly(this_many).times

        delete :destroy, params: { id: question.id }
      end

      it { expect(response).to redirect_to('/exchanges/security_questions') }

      context "when attempting to delete a question that has been answered already" do
        let!(:true_if_allowed) { false }
        let(:this_many) { 0 }
        it { expect(response).to redirect_to('/exchanges/security_questions') }
      end
    end
  end
end
