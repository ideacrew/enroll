require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe BrokerAgencyAccountObserver, type: :model, dbclean: :after_each do
      subject { BrokerAgencyAccountObserver.new }

      before do
        allow(subject).to receive(:notify).exactly(1).times
      end

      context 'when employer hired a broker' do

        let(:account) { build :benefit_sponsors_accounts_broker_agency_account }

        before do
          subject.broker_hired?(account)
          subject.broker_fired?(account)
        end

        it 'should notify hired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).to have_received(:notify).with("acapi.info.events.employer.broker_added", {employer_id: sponsor.hbx_id, event_name: "broker_added"})
        end

        it 'should not notify fired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_terminated", {employer_id: sponsor.hbx_id, event_name: "broker_terminated"})
        end
      end

      context 'when employer fired a broker' do

        let(:account) { create :benefit_sponsors_accounts_broker_agency_account }

        before do
          account.assign_attributes({
            is_active: false
          })

          subject.broker_hired?(account)
          subject.broker_fired?(account)
        end

        it 'should notify fired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).to have_received(:notify).with("acapi.info.events.employer.broker_terminated", {employer_id: sponsor.hbx_id, event_name: "broker_terminated"})
        end

        it 'should not notify hired event' do
          sponsor = account.benefit_sponsorship.profile
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.broker_added", {employer_id: sponsor.hbx_id, event_name: "broker_added"})
        end
      end
    end
  end
end
