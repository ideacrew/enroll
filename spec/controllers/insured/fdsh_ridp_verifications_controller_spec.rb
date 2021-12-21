require 'rails_helper'

describe Insured::FdshRidpVerificationsController do

  describe 'find response' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let!(:primary_event) { ::Fdsh::Ridp::EligibilityResponseModel.create(event_kind: 'primary', primary_member_hbx_id: person.hbx_id) }

    it 'finds a primary response' do
        controller.instance_variable_set(:@person, person)
        expect(controller.find_response('primary')).to eq(primary_event)
    end
  end

end