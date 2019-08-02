# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Observers::EdiObserver, dbclean: :after_each do

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
  let!(:event) {"benefit_coverage_period_terminated_nonpayment"}
  let!(:recipient) {model_instance.employer_profile}
  let!(:event_object) {model_instance}

  subject { BenefitSponsors::Services::EdiService.new }

  describe "deliver" do
    it "should trigger edi event" do
      expect(subject).to receive(:trigger_edi_event) do |recipient, event_object,event_name, edi_params|
        expect(recipient).to eq model_instance.employer_profile
        expect(event_object).to eq model_instance
        expect(event_name).to eq event
        expect(edi_params[:plan_year_id]).to eq ''
      end
      subject.deliver(recipient: recipient, event_object: event_object, event_name: event, edi_params: { plan_year_id: '' })
    end
  end

  describe "trigger_edi_event" do

    it "should notify event" do
      expect(subject).to receive(:notify).with("acapi.info.events.employer.#{event}", {employer_id: recipient.hbx_id, event_name: event, is_trading_partner_publishable: false, plan_year_id: nil})
      subject.trigger_edi_event(model_instance.employer_profile, model_instance, event, {})
    end

  end
end