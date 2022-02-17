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
end