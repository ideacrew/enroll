require 'rails_helper'

describe 'ModelEvents::SepRequestDenialNotice', :dbclean => :after_each  do
  let(:notice_event) { "sep_request_denial_notice" }
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, :aasm_state => 'enrolling' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id) }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer_profile)}
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop") }
  let(:sep) { FactoryGirl.create(:special_enrollment_period, family: person.primary_family, qualifying_life_event_kind_id: qle.id) }
  let(:qle_reporting_deadline) {TimeKeeper.date_of_record}
  let(:qle_event_on) { qle_reporting_deadline.next_day}

  describe "NoticeTrigger" do
    context "when employee matches er roster" do
      subject { Observers::Observer.new }
      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.sep_request_denial_notice"
          expect(payload[:event_object_kind]).to eq 'QualifyingLifeEventKind'
          expect(payload[:event_object_id]).to eq qle.id.to_s
        end
        subject.trigger_notice(recipient: employee_role, event_object: qle, notice_event: "sep_request_denial_notice")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?",
        "employee_profile.qle.title",
        "employee_profile.qle.start_on",
        "employee_profile.qle.end_on",
        "employee_profile.qle.event_on",
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "QualifyingLifeEventKind",
        "event_object_id" => qle.id,
        "qle_event_on" => qle_event_on.to_s,
        "qle_reporting_deadline" => qle_reporting_deadline.to_s
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
    end

    it "should return employee first name " do
      expect(merge_model.first_name).to eq person.first_name
    end

    it "should return employee last name " do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end

    context "with QLE data_elements" do
      it "should return qle_title" do
        expect(merge_model.qle.title).to eq qle.title
      end

      it "should return qle_start_on" do
        expect(merge_model.qle.start_on).to eq qle.start_on
      end

      it "should return qle_end_on" do
        expect(merge_model.qle.end_on).to eq qle.end_on
      end

      it "should return qle_event_on" do
        expect(merge_model.qle.event_on).to eq  Date.strptime(payload['qle_event_on'], '%m/%d/%Y')
      end
    end
  end
end