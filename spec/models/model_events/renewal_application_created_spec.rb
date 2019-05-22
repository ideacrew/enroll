require 'rails_helper'

RSpec.describe 'ModelEvents::RenewalApplicationCreated', dbclean: :around_each  do

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month.prev_month.prev_year}
  let!(:employer_profile)       { FactoryGirl.create(:employer_profile) }
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }

  let(:renewal_plan_year_start_on)  { plan_year.end_on.next_day }
  let(:renewal_open_enrollment_end_on)  { Date.new((renewal_plan_year_start_on - 1.month).year, (renewal_plan_year_start_on - 1.month).month, Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on) }

  let(:renewal_plan_year) {
    employer_profile.plan_years.build({
      start_on: renewal_plan_year_start_on,
      end_on: plan_year.end_on.next_year.end_of_month,
      open_enrollment_start_on: renewal_plan_year_start_on - 2.months,
      open_enrollment_end_on: renewal_open_enrollment_end_on,
      fte_count: plan_year.fte_count,
      pte_count: plan_year.pte_count,
      msp_count: plan_year.msp_count
    })
  }

  describe "when ER is renewed" do

    context "ModelEvent" do
      it "should trigger model event" do
        renewal_plan_year.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_created, :klass_instance => renewal_plan_year, :options => {})
          end
        end
        renewal_plan_year.renew_plan_year
        renewal_plan_year.save
      end
    end

    context "NoticeTrigger" do

      let(:subject)     { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_application_created, renewal_plan_year, {}) }

      context 'for non-conversion employer' do

        before do
          renewal_plan_year.renew_plan_year
          renewal_plan_year.save
        end

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employer.renewal_application_created"
            expect(payload[:event_object_kind]).to eq 'PlanYear'
            expect(payload[:event_object_id]).to eq renewal_plan_year.id.to_s
          end
          subject.plan_year_update(model_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      renewal_plan_year.renew_plan_year
      renewal_plan_year.save
    end

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.plan_year.renewal_py_oe_end_date",
          "employer_profile.plan_year.renewal_py_submit_due_date",
          "employer_profile.employer_name"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => renewal_plan_year.id.to_s
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return renewal plan year due date to publish" do
      expect(merge_model.plan_year.renewal_py_submit_due_date).to eq Date.new(renewal_plan_year_start_on.prev_month.year, renewal_plan_year_start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month).strftime('%m/%d/%Y')
    end

    it "should return renewal plan year oe end on" do
      expect(merge_model.plan_year.renewal_py_oe_end_date).to eq renewal_plan_year.open_enrollment_end_on.strftime('%m/%d/%Y')
    end
  end
end