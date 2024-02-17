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
      expect(controller.find_response('primary')).to eq(primary_event)
    end

    context "with nil deleted at dates" do

      it "should not include eligibility response models" do
        expect(controller.find_response('primary').to_a.count).to eql(1)
      end
    end

    context "with no records" do

      before do
        controller.instance_variable_set(:@person, person2)
      end

      it "should return nil" do
        expect(controller.find_response('primary')).to eql(nil)
      end
    end

    context "with multiple records with different primary hbx_id" do

      before do
        controller.instance_variable_set(:@person, person1)
      end

      it "should only return records related to one primary hbx_id" do
        expect(controller.find_response('primary').to_a.count).to eql(1)
      end
    end

    context "with different event kinds" do

      it "should only return one event kind" do
        expect(controller.find_response('secondary')).to eql(fifth_event)
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

      context "when tried to access unauthorized person" do
        let(:person_B){ FactoryBot.create(:person, :with_consumer_role) }
        let!(:user_B){ FactoryBot.create(:user, person: person_B) }

        it "should redirect with authorization error" do
          get :failed_validation, params: {person_id: person_B.id.to_s}

          expect(response).to have_http_status(:redirect)
          expect(flash[:error]).to eq("Access not allowed for person_policy.can_access_identity_verifications?, (Pundit policy)")
        end
      end
    end
  end
end