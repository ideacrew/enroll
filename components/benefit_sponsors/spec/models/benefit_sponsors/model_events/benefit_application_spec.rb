require 'rails_helper'

RSpec.describe BenefitSponsors::ModelEvents::BenefitApplication, dbclean: :after_each do

  let!(:nonpayment_model_event) { "benefit_coverage_period_terminated_nonpayment" }
  let(:voluntary_model_event) { "benefit_coverage_period_terminated_voluntary" }
  let(:carrier_drop_model_event) { "benefit_coverage_renewal_carrier_dropped" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryBot.create(:benefit_sponsors_benefit_application,
                                             :with_benefit_package,
                                             :benefit_sponsorship => benefit_sponsorship,
                                             :aasm_state => 'active',
                                             :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}


  shared_examples_for "for employer plan year action" do |action, event|
    it "should create model event and should have attributes" do
      model_instance.class.observer_peers.keys.each do |observer|
        expect(observer).to receive(:notifications_send) do |model_instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => event.to_sym, :klass_instance => model_instance, :options => {})
        end
        if action == "cancel"
          model_instance.cancel!
        else
          model_instance.termination_kind = action
          model_instance.terminate_enrollment!
        end
      end
    end
  end

  # TODO: EDI related specs should be moved a different observer.
  xdescribe "Employer ModelEvent" do
    it_behaves_like "for employer plan year action", "nonpayment", "benefit_coverage_period_terminated_nonpayment"
    it_behaves_like "for employer plan year action", "voluntary", "benefit_coverage_period_terminated_voluntary"
    it_behaves_like "for employer plan year action", "cancel", "benefit_coverage_renewal_carrier_dropped"
  end
end
