require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe EmployerProfileObserver, type: :model do
      let(:employer_profile) { create :benefit_sponsors_organizations_aca_shop_cca_employer_profile }

      before do
        allow(employer_profile).to receive(:notify_observers).and_call_original
      end

      subject do
        employer_profile.update_attributes! office_locations_attributes: {
          '0' => {
            id: employer_profile.office_locations.first.id,
            address_attributes: {
              address_1: '1114 Cool St'
            }
          }
        }
      end

      it 'notifies observers' do
        subject
        expect(employer_profile).to have_received(:notify_observers)
      end

      it 'sends a notification' do
        expect_any_instance_of(EmployerProfileObserver).to receive(:update)
        subject
      end
    end
  end
end
