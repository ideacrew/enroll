require 'rails_helper'

RSpec.describe Exchanges::SecurityQuestionsController do

  let(:user) { FactoryGirl.create(:user, with_security_questions: false) }
  let(:person) { FactoryGirl.create(:person, user: user) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }
  let(:question) { FactoryGirl.create(:security_question) }

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return true
    sign_in user
  end
  after { SecurityQuestion.destroy_all }

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
      before { post :create, security_question: { title: nil } }
      it { expect(assigns(:question).title).to be_nil }
      it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/new') }
    end

    context 'When question is created successfully' do
      before { post :create, security_question: { title: 'First Question' } }
      it { expect(assigns(:question)).to be_a(SecurityQuestion) }
      it { expect(SecurityQuestion.all).not_to eq([]) }
      it { expect(assigns(:question).title).to eq('First Question') }
      it { expect(response).to redirect_to('/exchanges/security_questions') }
    end
  end

  describe 'GET edit' do
    before { get :edit, id: question.id }
    it { expect(assigns(:question)).to eq(question) }
    it { expect(response).to have_http_status(:success) }
    it { expect(response).to render_template('exchanges/security_questions/edit') }
  end

  describe 'PUT update' do
    context 'When update question with blank title' do
      before { put :update, id: question.id, security_question: { title: nil } }
      it { expect(assigns(:question)).to eq(question) }
      it { expect(assigns(:question).errors.full_messages).to eq(['Title can\'t be blank']) }
      it { expect(response).to have_http_status(:success) }
      it { expect(response).to render_template('exchanges/security_questions/edit') }
    end

    context 'When update question with valid title' do
      before { put :update, id: question.id, security_question: { title: 'Updated title' } }
      it { expect(assigns(:question)).to eq(question) }
      it { expect(assigns(:question).title).to eq('Updated title') }
      it { expect(response).to redirect_to('/exchanges/security_questions') }
    end
  end

  describe 'DELETE destroy' do
    before { delete :destroy, id: question.id }
    it { expect(SecurityQuestion.all.to_a).to eq([]) }
    it { expect(response).to redirect_to('/exchanges/security_questions') }
  end

end
