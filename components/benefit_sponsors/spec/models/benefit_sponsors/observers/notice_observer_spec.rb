# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Observers::NoticeObserver, dbclean: :after_each do

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


  subject { BenefitSponsors::Observers::NoticeObserver.new }

  shared_examples_for "benefit application event" do |event|
    let!(:event_type) {event.to_sym}

    let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(event_type, model_instance, {}) }

    it "deliver event should have" do
      expect(subject).to receive(:deliver) do |recipient:, event_object:,notice_event:|
        expect(recipient).to eq model_instance.employer_profile
        expect(event_object).to eq model_instance
        expect(notice_event).to match(/#{event}/i)
      end
      subject.process_application_events(model_instance, model_event)
    end

    it "notify event should have" do
      expect(subject.notifier).to receive(:notify) do |event_name, payload|
        expect(event_name).to match(/#{event_name}/i)
        expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
      end
      subject.process_application_events(model_instance, model_event)
    end
  end

  describe "notify benefit application events" do
    it_behaves_like "benefit application event", "application_denied"
  end
end
