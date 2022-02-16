#frozen_string_literal: true

require 'rails_helper'

describe Insured::FdshRidpVerificationsController do

  describe 'find response' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let!(:primary_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: DateTime.now) }
    let!(:secondary_event) {::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id, deleted_at: nil)}

    before do
      controller.instance_variable_set(:@person, person)
    end

    it 'finds a primary response' do
      expect(controller.find_response('primary')).to eq(primary_event)
    end

    it "should not include eligibility response models with nil deleted at dates" do
      expect(controller.find_response('primary').to_a.count).to eql(1)
    end
  end
end