require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::RenewalApplicationCreated', dbclean: :around_each  do

  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_effective_date)  { TimeKeeper.date_of_record }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                  benefit_market: benefit_market,
                                  title: "SHOP Benefits for #{current_effective_date.year}",
                                  application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                }
  let!(:model_instance) {
    application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, 
      aasm_state: "draft", 
      benefit_sponsorship: benefit_sponsorship
      )
    application.benefit_sponsor_catalog.save!
    application
  }

  # let!(:renewing_benefit_application) {
  #   application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, 
  #     aasm_state: "draft", 
  #     benefit_sponsorship: benefit_sponsorship
  #     )
  #   application.predecessor = model_instance
  #   application.benefit_packages.first.predecessor = model_instance.benefit_packages.first
  #   application.benefit_sponsor_catalog.save!
  #   application
  # }

  describe "when renewal application created" do
    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.each do |observer|
          expect(observer).to receive(:notifications_send) do |model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_created, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.notify_on_create
        model_instance.save
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::BenefitApplicationObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:renewal_application_created, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_application_created"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.notifications_send(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.renewal_py_start_date",
        "employer_profile.benefit_application.renewal_py_submit_soft_due_date",
        "employer_profile.benefit_application.renewal_py_oe_end_date",
        "employer_profile.benefit_application.current_py_start_on.year",
        "employer_profile.benefit_application.renewal_py_start_on.year",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { { 
      "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
      "event_object_id" => model_instance.id
    } }

    let(:soft_dead_line) { Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline) }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.notify_on_create
        model_instance.save
      end

      it "should build the data elements for the notice" do
        merge_model = subject.construct_notice_object

        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        expect(merge_model.employer_name).to eq employer_profile.legal_name
        expect(merge_model.benefit_application.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        expect(merge_model.benefit_application.renewal_py_submit_soft_due_date).to eq soft_dead_line.strftime('%m/%d/%Y')
        expect(merge_model.benefit_application.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.benefit_application.current_py_start_on).to eq model_instance.start_on.prev_year
        expect(merge_model.benefit_application.renewal_py_start_on).to eq model_instance.start_on
      end 
    end
  end
end