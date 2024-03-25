#frozen_string_literal: true

require 'rails_helper'

describe Insured::FdshRidpVerificationsController do

  describe 'find response' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:person1) { FactoryBot.create(:person, :with_family) }
    let(:person2) { FactoryBot.create(:person, :with_family) }
    let!(:primary_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: DateTime.now) }
    let!(:secondary_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: nil)}
    let!(:third_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person1.hbx_id, deleted_at: DateTime.now)}
    let!(:fourth_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person1.hbx_id, deleted_at: DateTime.now - 2.day)}
    let!(:fifth_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'secondary', primary_member_hbx_id: person.hbx_id, deleted_at: DateTime.now) }

    before do
      controller.instance_variable_set(:@person, person)
    end

    it 'finds a primary response' do
      expect(controller.send(:find_response, 'primary')).to eq(primary_event)
    end

    context "with nil deleted at dates" do

      it "should not include eligibility response models" do
        expect(controller.send(:find_response, 'primary').to_a.count).to eql(1)
      end
    end

    context "with no records" do
      before do
        controller.instance_variable_set(:@person, person2)
      end

      it "should return nil" do
        expect(controller.send(:find_response, 'primary')).to eql(nil)
      end
    end

    context "with multiple records with different primary hbx_id" do

      before do
        controller.instance_variable_set(:@person, person1)
      end

      it "should only return records related to one primary hbx_id" do
        expect(controller.send(:find_response, 'primary').to_a.count).to eql(1)
      end
    end

    context "with different event kinds" do

      it "should only return one event kind" do
        expect(controller.send(:find_response, 'secondary')).to eql(fifth_event)
      end
    end
  end

  describe '.failed_validation' do
    let(:user){ FactoryBot.create(:user, :consumer, person: person) }
    let(:person){ FactoryBot.create(:person, :with_consumer_role) }

    context "GET failed_validation", dbclean: :after_each do
      before(:each) do
        sign_in user
        allow(user).to receive(:person).and_return(person)
      end

      it "should render template" do
        allow_any_instance_of(ConsumerRole).to receive(:move_identity_documents_to_outstanding).and_return(true)
        get :failed_validation, params: {}

        expect(response).to have_http_status(:success)
        expect(response).to render_template("failed_validation")
      end
    end
  end
end

describe Insured::FdshRidpVerificationsController, "given an unauthorized user" do
  let(:mock_user) do
    instance_double(
      User,
      :has_hbx_staff_role? => false,
      :person => mock_person
    )
  end
  let(:mock_person) do
    double(
      policy_class: PersonPolicy,
      :agent? => false
    )
  end
  let(:mock_policy) do
    instance_double(
      PersonPolicy,
      :complete_ridp? => false
    )
  end

  before :each do
    allow(PersonPolicy).to receive(:new).with(mock_user, mock_person).and_return(mock_policy)
    sign_in(mock_user)
  end

  it "denies access to GET #new" do
    get :new
    expect(response.status).to eq 302
  end

  it "denies access to POST #create" do
    post :create, params: {}
    expect(response.status).to eq 302
  end

  it "denies access to GET #service_unavailable" do
    get :service_unavailable
    expect(response.status).to eq 302
  end

  it "denies access to GET #failed_validation" do
    get :failed_validation
    expect(response.status).to eq 302
  end

  it "denies access to GET #wait_for_primary_response" do
    get :wait_for_primary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #wait_for_secondary_response" do
    get :wait_for_secondary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #check_primary_response_received" do
    get :check_primary_response_received
    expect(response.status).to eq 302
  end

  it "denies access to GET #check_secondary_response_received" do
    get :check_secondary_response_received
    expect(response.status).to eq 302
  end

  it "denies access to GET #primary_response" do
    get :primary_response
    expect(response.status).to eq 302
  end

  it "denies access to GET #secondary_response" do
    get :secondary_response
    expect(response.status).to eq 302
  end
end