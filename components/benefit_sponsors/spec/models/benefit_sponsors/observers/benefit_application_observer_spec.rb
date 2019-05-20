# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Observers::BenefitApplicationObserver, dbclean: :after_each do

  let(:nonpayment_model_event) { "benefit_coverage_period_terminated_nonpayment" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) do
    FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_package,
      :benefit_sponsorship => benefit_sponsorship,
      :aasm_state => 'active',
      :effective_period => start_on..(start_on + 1.year) - 1.day
    )
  end

  subject { BenefitSponsors::Observers::BenefitApplicationObserver.new }

  shared_examples_for "employer event" do |event|
    let!(:event_type) {event.to_sym}

    let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(event_type, model_instance, {}) }

    it "notify event should have" do
      expect(subject).to receive(:notify) do |event_name, payload|
        expect(event_name).to eq "acapi.info.events.employer.#{event}"
        expect(payload[:employer_id]).to eq model_instance.employer_profile.hbx_id
        expect(payload[:is_trading_partner_publishable]).to eq false
        expect(payload[:event_name]).to eq event
        expect(payload[:benefit_application_id]).to eq model_instance.id.to_s if event == "benefit_coverage_renewal_carrier_dropped"
      end
      subject.notifications_send(model_instance, model_event)
    end
  end

  # TODO: Need to move the events to a different observer
  xdescribe "Notify Employer Plan Year Event" do
    it_behaves_like "employer event", "benefit_coverage_period_terminated_nonpayment"
    it_behaves_like "employer event", "benefit_coverage_period_terminated_voluntary"
    it_behaves_like "employer event", "benefit_coverage_renewal_carrier_dropped"
  end
end
