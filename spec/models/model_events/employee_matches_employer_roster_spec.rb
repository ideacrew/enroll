require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeMatchesEmployerRoster', :dbclean => :after_each  do
  let(:notice_event) { "employee_matches_employer_roster" }
  let(:organization) { FactoryGirl.create(:organization, :with_active_plan_year) }
  let(:employer_profile) { organization.employer_profile }
  let(:plan_year) { employer_profile.plan_years.first }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let(:family) {person.primary_family}
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:model_instance) { FactoryGirl.build(:employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id) }

  describe "ModelEvent" do
    context "when employee creates account" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employee_role_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_matches_employer_roster, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when EE matches ER roster" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_matches_employer_roster, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_matches_employer_roster"
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq census_employee.id.to_s
        end
        subject.employee_role_update(model_event)
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
        "employee_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "CensusEmployee",
        "event_object_id" => census_employee.id
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
  end
end
