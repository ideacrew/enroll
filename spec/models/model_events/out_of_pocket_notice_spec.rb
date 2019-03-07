require 'rails_helper'

RSpec.describe 'ModelEvents::OutOfPocketNotice', dbclean: :after_each do

  let!(:notice_event) { 'out_of_pocker_url_notifier' }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ FactoryGirl.create(:person, :with_family)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolling' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }

  describe "NoticeTrigger" do

    subject { Services::NoticeService.new }

    it "should trigger model event" do
      expect(subject).to receive(:notify) do |event_name, payload|
        expect(event_name).to eq "acapi.info.events.employer.out_of_pocker_url_notifier"
        expect(payload[:event_object_kind]).to eq 'EmployerProfile'
        expect(payload[:event_object_id]).to eq employer_profile.id.to_s
      end
      subject.deliver(recipient: employer_profile, event_object: employer_profile, notice_event: notice_event, notice_params: {})
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => 'EmployerProfile',
        "event_object_id" => employer_profile.id.to_s
    } }

    context "when notice event is received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end