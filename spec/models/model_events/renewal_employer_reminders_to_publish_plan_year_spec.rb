require 'rails_helper'

describe 'ModelEvents::RenewalEmployerRemindersToPublishPlanYear', dbclean: :after_each do

  let(:start_on) { (TimeKeeper.date_of_record.beginning_of_month + 2.months).prev_year }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

  EVENTS_DATES_PAIR = {
    "renewal_employer_first_reminder_to_publish_plan_year" => 3,
    "renewal_employer_second_reminder_to_publish_plan_year" => 4,
    "renewal_employer_third_reminder_to_publish_plan_year" => 8
  }

  EVENTS_DATES_PAIR.each do |event, date|

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(start_on.next_year.year, start_on.prev_month.month, date))
    end

    after :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    describe "ModelEvent" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(event.to_sym, PlanYear, {}) }

      context "2 days prior to renewing application soft deadline" do
        it "should trigger model event" do
          expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employer_profile, event_object: model_instance, notice_event: event).and_return(true)
          PlanYear.date_change_event(Date.new(start_on.next_year.year, start_on.prev_month.month, date))
        end

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employer.#{event}"
            expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
            expect(payload[:event_object_kind]).to eq 'PlanYear'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.plan_year_date_change(model_event)
        end
      end
    end

    describe "NoticeBuilder" do

      let(:data_elements) {
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.plan_year.renewal_py_start_date",
          "employer_profile.plan_year.renewal_py_submit_soft_due_date",
          "employer_profile.plan_year.renewal_py_submit_due_date",
          "employer_profile.plan_year.renewal_py_oe_end_date",
          "employer_profile.plan_year.current_year",
          "employer_profile.plan_year.renewal_year",
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
          "event_object_kind" => "PlanYear",
          "event_object_id" => model_instance.id
      } }

      context "when notice event received" do

        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        before do
          allow(subject).to receive(:resource).and_return(employer_profile)
          allow(subject).to receive(:payload).and_return(payload)
          PlanYear.date_change_event(Date.new(start_on.next_year.year, start_on.prev_month.month, date))
        end

        it "should retrun merge mdoel" do
          expect(merge_model).to be_a(recipient.constantize)
        end

        it "should return the date of the notice" do
          expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        end

        it "should return employer name" do
          expect(merge_model.employer_name).to eq employer_profile.legal_name
        end

        it "should return renewing plan year start date" do
          expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        end

        it "should return renewal application advertised soft deadline of month" do
          expect(merge_model.plan_year.renewal_py_submit_soft_due_date).to eq Date.new(model_instance.start_on.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline).strftime('%m/%d/%Y')
        end

        it "should return current year" do
          expect(merge_model.plan_year.current_year).to eq plan_year.start_on.year.to_s
        end

        it "should return renewal year" do
          expect(merge_model.plan_year.renewal_year).to eq model_instance.start_on.year.to_s
        end

        it "should return renewal application deadline of month" do
          expect(merge_model.plan_year.renewal_py_submit_due_date).to eq Date.new(model_instance.start_on.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month).strftime('%m/%d/%Y')
        end

        it "should return false when there is no broker linked to employer" do
          expect(merge_model.broker_present?).to be_falsey
        end
      end
    end
  end
end