# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::GroupTerminationNotice', :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person)       { FactoryBot.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment,  benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package) }
  let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id)}
  let(:hbx_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :with_product,
      household: family.active_household,
      aasm_state: "coverage_selected",
      effective_on: initial_application.start_on,
      rating_area_id: initial_application.recorded_rating_area_id,
      sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
      sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
      benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
      employee_role_id: employee_role.id
    )
  end

  let(:model_instance) { initial_application }
  let(:end_date) { TimeKeeper.date_of_record.prev_month.end_of_month }
  let(:termination_date) { TimeKeeper.date_of_record }
  let(:service) { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(model_instance) }

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe 'when employer is terminated from shop' do
    context 'ModelEvent' do
      it 'should trigger model event' do
        model_instance.class.observer_peers.keys.select { |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_application_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :group_advance_termination_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        service.terminate(end_date, termination_date, "voluntary", false)
      end
    end

    context 'NoticeTrigger' do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:group_advance_termination_confirmation, model_instance, {}) }
      it 'should trigger notice event' do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.group_advance_termination_confirmation"
          expect(payload[:employer_id]).to eq abc_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq "BenefitSponsors::BenefitApplications::BenefitApplication"
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_group_advance_termination"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance, model_event)
      end
    end
  end

  describe 'NoticeBuilder' do
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:merge_model) { subject.construct_notice_object }

    context 'when notice received to employer' do
      let(:data_elements) do
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.first_name",
          "employer_profile.last_name",
          "employer_profile.benefit_application.current_py_end_date",
          "employer_profile.benefit_application.current_py_plus_60_days",
          "employer_profile.broker_present?",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email"
        ]
      end

      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:payload) do
        {
          "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
          "event_object_id" => model_instance.id
        }
      end

      before do
        allow(subject).to receive(:resource).and_return(abc_profile)
        allow(subject).to receive(:payload).and_return(payload)
        service.terminate(end_date, termination_date, "voluntary", false)
      end

      it 'should retrun merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it 'should return plan year end date' do
        expect(merge_model.benefit_application.current_py_end_date).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it 'should return plan year end date plus 60 days' do
        expect(merge_model.benefit_application.current_py_plus_60_days).to eq(model_instance.end_on + 60.days).strftime('%m/%d/%Y')
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end

    context 'when notice received to employee' do
      let(:data_elements) do
        [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.benefit_application.current_py_end_date",
          "employee_profile.benefit_application.current_py_plus_60_days",
          "employee_profile.broker_present?",
          "employee_profile.broker.primary_fullname",
          "employee_profile.broker.organization",
          "employee_profile.broker.phone",
          "employee_profile.broker.email"
        ]
      end

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:payload) do
        {
          "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
          "event_object_id" => model_instance.id
        }
      end

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        service.terminate(end_date, termination_date, "voluntary", false)
      end

      it 'should retrun merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employee first name' do
        expect(merge_model.first_name).to eq census_employee.employee_role.person.first_name
      end

      it 'should return employee last name' do
        expect(merge_model.last_name).to eq census_employee.employee_role.person.last_name
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
      end

      it 'should return plan year end date' do
        expect(merge_model.benefit_application.current_py_end_date).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it 'should return plan year end date plus 60 days' do
        expect(merge_model.benefit_application.current_py_plus_60_days).to eq(model_instance.end_on + 60.days).strftime('%m/%d/%Y')
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
