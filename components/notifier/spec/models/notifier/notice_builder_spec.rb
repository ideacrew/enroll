require 'rails_helper'


RSpec.describe Notifier::NoticeBuilder, type: :model do

  describe '.validate_merge_model' do

    let(:data_elements_with_broker_conditions_only) do
      [
        'employee_profile.notice_date',
        'employee_profile.employer_name',
        'employee_profile.plan_year.current_py_start_date',
        'employee_profile.plan_year.binder_payment_due_date',
        'employee_profile.broker.primary_fullname',
        'employee_profile.broker.organization',
        'employee_profile.broker.phone',
        'employee_profile.broker.email',
        'employee_profile.broker_present?'
      ]
    end

    let(:employee_recipient) { 'Notifier::MergeDataModels::EmployeeProfile' }
    let(:employer_recipient) { 'Notifier::MergeDataModels::EmployerProfile' }

    context 'when data elements with only broker conditions are present' do

      let(:template)  { Notifier::Template.new(data_elements: data_elements_with_broker_conditions_only, raw_body: '<p>\#{Settings.site.short_name}</p>') }

      subject { Notifier::NoticeKind.new(template: template, recipient: employee_recipient) }

      let!(:person) { FactoryGirl.create(:person, :with_family) }
      let(:family)  { person.primary_family }
      let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
      let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: person) }
      let!(:model_instance) do
        FactoryGirl.create(:hbx_enrollment,
                           :with_enrollment_members,
                           household: family.active_household,
                           employee_role_id: employee_role.id,
                           aasm_state: "coverage_enrolled",
                           benefit_group_id: benefit_group.id)
      end

      let(:payload) do
        {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
        }
      end

      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return true' do
        expect(subject.validate_data_object(merge_model)).to be_truthy
      end
    end

    context 'when data elements are missing' do

      let(:template)  { Notifier::Template.new(data_elements: data_elements_with_broker_conditions_only, raw_body: '<p>\#{Settings.site.home_url}</p>\r\n\r\n<p>\#{Settings.site.help_url}</p>\r\n\r\n<p>\#{Settings.site.short_name}</p>\r\n') }

      subject { Notifier::NoticeKind.new(template: template, recipient: employee_recipient) }

      let!(:person) { FactoryGirl.create(:person, :with_family) }
      let(:family)  { person.primary_family }
      let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
      let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: person) }
      let!(:model_instance) do
        FactoryGirl.create(:hbx_enrollment,
                           :with_enrollment_members,
                           household: family.active_household,
                           employee_role_id: employee_role.id,
                           aasm_state: "coverage_enrolled",
                           benefit_group_id: benefit_group.id)
      end

      let(:payload) do
        {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
        }
      end

      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should raise an exception' do
        expect{ subject.validate_data_object(merge_model) }.to raise_error("Missing token - Settings.site.help_url for event  recipient - #{employee_role.class} id - #{employee_role.id}")
      end
    end

    context 'when data elements with loops are present' do

      let(:data_elements_with_loops) do
        [
          'employer_profile.notice_date',
          'employer_profile.account_number',
          'employer_profile.total_amount_due',
          'employer_profile.invoice_number',
          'employer_profile.broker.primary_fullname',
          'employer_profile.broker.organization',
          'employer_profile.broker.phone',
          'employer_profile.broker.email',
          'employer_profile.broker_present?',
          'employer_profile.offered_products'
        ]
      end

      let(:template)  { Notifier::Template.new(data_elements: data_elements_with_loops) }

      subject { Notifier::NoticeKind.new(template: template, recipient: employer_recipient) }

      let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
      let(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolled') }
      let(:person){ FactoryGirl.create(:person, :with_family)}
      let(:family) { person.primary_family}
      let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
      let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
      let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
      let(:benefit_group_assignment)    { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, start_on: start_on, benefit_group_id: benefit_group.id, hbx_enrollment_id: hbx_enrollment.id) }
      let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month, is_subscriber: true) }
      let!(:hbx_enrollment) do
        FactoryGirl.create(:hbx_enrollment,
                           household: family.active_household,
                           employee_role_id: employee_role.id,
                           benefit_group_id: benefit_group.id,
                           hbx_enrollment_members: [hbx_enrollment_member],
                           effective_on: start_on)
      end

      let(:payload) do
        {
          'event_object_kind' => 'PlanYear',
          'event_object_id' => plan_year.id
        }
      end

      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should skip validation' do
        expect(subject.validate_data_object(merge_model)).to be_truthy
      end
    end

    context 'when data elements with conditions other than brokers are present' do

      let(:data_elements_with_conditions_other_than_broker) do
        [
          'employee_profile.notice_date',
          'employee_profile.employer_name',
          'employee_profile.plan_year.current_py_start_date',
          'employee_profile.plan_year.binder_payment_due_date',
          'employee_profile.broker.primary_fullname',
          'employee_profile.broker.organization',
          'employee_profile.broker.phone',
          'employee_profile.broker.email',
          'employee_profile.broker_present?',
          'employee_profile.census_employee_health_enrollment?',
          'employee_profile.census_employee_dental_enrollment?'
        ]
      end

      let(:template)  { Notifier::Template.new(data_elements: data_elements_with_conditions_other_than_broker) }

      subject { Notifier::NoticeKind.new(template: template, recipient: employee_recipient) }

      let!(:person) { FactoryGirl.create(:person, :with_family) }
      let(:family)  { person.primary_family }
      let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
      let!(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
      let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: person) }
      let!(:model_instance) do
        FactoryGirl.create(:hbx_enrollment,
                           :with_enrollment_members,
                           household: family.active_household,
                           employee_role_id: employee_role.id,
                           benefit_group_id: benefit_group.id,
                           aasm_state: "shopping",
                           benefit_group_assignment_id: benefit_group_assignment.id)
      end

      let(:payload) do
        {
          'event_object_kind' => 'HbxEnrollment',
          'event_object_id' => model_instance.id
        }
      end

      let(:merge_model) { subject.construct_notice_object }

      before do
        model_instance.waive_coverage!
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should skip validation' do
        expect(subject.validate_data_object(merge_model)).to be_truthy
      end
    end
  end
end