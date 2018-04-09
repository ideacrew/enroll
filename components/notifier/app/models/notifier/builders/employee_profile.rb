module Notifier
  class Builders::EmployeeProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker

    attr_accessor :employee_role, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.census_employee = Notifier::MergeDataModels::CensusEmployee.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employee_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def first_name
      merge_model.first_name = employee_role.person.first_name if employee_role.present?
    end

    def last_name
      merge_model.last_name = employee_role.person.last_name if employee_role.present?
    end

    def append_contact_details
      mailing_address = employee_role.person.mailing_address
      if mailing_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: mailing_address.address_1,
          street_2: mailing_address.address_2,
          city: mailing_address.city,
          state: mailing_address.state,
          zip: mailing_address.zip
          })
      end
    end

    def employer_name
      merge_model.employer_name = employee_role.employer_profile.legal_name
    end

    def census_employee_record
      employee_role.census_employee
    end

    def date_of_hire
      merge_model.date_of_hire = format_date(census_employee_record.hired_on)
    end

    def termination_of_employment
      merge_model.termination_of_employment = format_date(census_employee_record.employment_terminated_on)
    end

    def coverage_terminated_on
      merge_model.coverage_terminated_on = format_date(census_employee_record.coverage_terminated_on)
    end

    def earliest_coverage_begin_date
      merge_model.earliest_coverage_begin_date = format_date census_employee_record.coverage_effective_on
    end

    def new_hire_oe_start_date
      merge_model.new_hire_oe_start_date = format_date(census_employee_record.new_hire_enrollment_period.min)
    end

    def new_hire_oe_end_date
      merge_model.new_hire_oe_end_date = format_date(census_employee_record.new_hire_enrollment_period.max)
    end

    def census_employee_health_enrollment?
      merge_model.census_employee.latest_terminated_health_enrollment_plan_name.present?
    end

    def census_employee_dental_enrollment?
      merge_model.census_employee.latest_terminated_dental_enrollment_plan_name.present?
    end

    def census_employee_health_and_dental_enrollment?
      census_employee_health_enrollment? && census_employee_dental_enrollment?
    end

    def census_employee_latest_terminated_health_enrollment_plan_name
      merge_model.census_employee.load_data(payload) if !merge_model.census_employee.is_data_initialized?
      merge_model.census_employee.latest_terminated_health_enrollment_plan_name
    end

    def census_employee_latest_terminated_dental_enrollment_plan_name
      merge_model.census_employee.load_data(payload) if !merge_model.census_employee.is_data_initialized?
      merge_model.census_employee.latest_terminated_dental_enrollment_plan_name
    end

    def employer_profile
      employee_role.employer_profile
    end
  end
end