module Notifier
  class Builders::EmployeeProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker

    attr_accessor :employee_role, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employee_role = resource
    end

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = Settings.aca.individual_market.open_enrollment.start_on.strftime('%m/%d/%Y')
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = Settings.aca.individual_market.open_enrollment.end_on.strftime('%m/%d/%Y')
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def email
      merge_model.email = employee_role.person.work_email_or_best if employee_role.present?
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

    def enrollment
      return @enrollment if defined? @enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.find(payload['event_object_id'])
      end
    end

    def enrollment_coverage_start_on
       return if enrollment.blank?
       merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_plan_name
      if enrollment.present?
        merge_model.enrollment.plan_name = enrollment.plan.name
      end
    end

    def enrollment_employee_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employee_responsible_amount = number_to_currency(current_premium(enrollment.total_employee_cost), precision: 2)
    end

    def enrollment_employer_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employer_responsible_amount = number_to_currency(current_premium(enrollment.total_employer_contribution), precision: 2)
    end

    def census_employee
      employee_role.census_employee
    end

    def date_of_hire
      merge_model.date_of_hire = format_date(census_employee.hired_on)
    end

    def earliest_coverage_begin_date
      merge_model.earliest_coverage_begin_date = format_date census_employee.coverage_effective_on
    end

    def new_hire_oe_start_date
      merge_model.new_hire_oe_start_date = format_date(census_employee.new_hire_enrollment_period.min)
    end

    def new_hire_oe_end_date
      merge_model.new_hire_oe_end_date = format_date(census_employee.new_hire_enrollment_period.max)
    end

    def employer_profile
      employee_role.employer_profile
    end
  end
end