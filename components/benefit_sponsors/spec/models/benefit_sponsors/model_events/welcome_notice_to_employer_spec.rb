require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::WelcomeNoticeToEmployer', dbclean: :around_each  do
  let(:notice_event)  { "welcome_notice_to_employer" }
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let(:person){ create :person}

  describe "NoticeTrigger" do
    context "when ER successfully creates account" do
      subject { BenefitSponsors::Observers::OrganizationObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.welcome_notice_to_employer"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.notifier.deliver(recipient: model_instance, event_object: model_instance, notice_event: notice_event)
      end
    end
  end

   describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.employer_name"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(model_instance)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end
  end
end
