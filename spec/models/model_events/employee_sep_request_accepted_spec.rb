require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeSepRequestAccepted', :dbclean => :after_each do
  let(:organization) { FactoryGirl.create(:organization, :with_active_plan_year) }
  let(:employer_profile) { organization.employer_profile }
  let(:plan_year) { employer_profile.plan_years.first }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let(:family) {person.primary_family}
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id) }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop") }
  let(:model_instance) { FactoryGirl.build(:special_enrollment_period, family: family, qualifying_life_event_kind_id: qle.id, title: "Married") }

  describe "ModelEvent" do
    context "when employee sep request accepted" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:special_enrollment_period_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_sep_request_accepted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end
  end

  describe "NoticeTrigger when employee is active on single roster" do
    context "when employee sep is accepted" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_sep_request_accepted, model_instance, {}) }

      before do
        fm = family.family_members.first
        allow(model_instance).to receive(:family).and_return(family)
        allow(family).to receive(:primary_applicant).and_return(fm)
        allow(fm).to receive(:person).and_return(person)
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload| 
          expect(event_name).to eq "acapi.info.events.employee.sep_accepted_notice_for_ee_active_on_single_roster"
          expect(payload[:event_object_kind]).to eq 'SpecialEnrollmentPeriod'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.special_enrollment_period_update(model_event)
      end
    end
  end

  describe "NoticeTrigger when employee is active on multiple roster" do
    context "when employee sep is accepted" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_sep_request_accepted, model_instance, {}) }
      let(:organization2) { FactoryGirl.create(:organization, :with_active_plan_year) }
      let(:employer_profile2) { organization.employer_profile }
      let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile2) }
      let!(:employee_role2) { FactoryGirl.create(:employee_role, employer_profile: employer_profile2, person: person, census_employee_id: census_employee.id) }

      before do
        fm = family.family_members.first
        allow(model_instance).to receive(:family).and_return(family)
        allow(family).to receive(:primary_applicant).and_return(fm)
        allow(fm).to receive(:person).and_return(person)
        census_employee.update_attributes(employee_role_id: employee_role.id)
      end

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload| 
          expect(event_name).to eq "acapi.info.events.employee.sep_accepted_notice_for_ee_active_on_multiple_rosters"
          expect(payload[:event_object_kind]).to eq 'SpecialEnrollmentPeriod'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.special_enrollment_period_update( model_event)
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
        "employee_profile.special_enrollment_period.title",
        "employee_profile.special_enrollment_period.start_on",
        "employee_profile.special_enrollment_period.end_on",
        "employee_profile.special_enrollment_period.qle_reported_on",
        "employee_profile.special_enrollment_period.submitted_at"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "SpecialEnrollmentPeriod",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      model_instance.save!
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
        expect(merge_model.special_enrollment_period.title).to eq model_instance.title
      end

      it "should return qle_start_on" do
        expect(merge_model.special_enrollment_period.start_on).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return qle_end_on" do
        expect(merge_model.special_enrollment_period.end_on).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it "should return qle_event_on" do
        expect(merge_model.special_enrollment_period.qle_reported_on).to eq model_instance.qle_on.strftime('%m/%d/%Y')
      end

      it "should return submitted_at" do
        expect(merge_model.special_enrollment_period.submitted_at).to eq model_instance.submitted_at.strftime('%m/%d/%Y')
      end
    end
  end
end