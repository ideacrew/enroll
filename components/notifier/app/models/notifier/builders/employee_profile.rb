module Notifier
  class Builders::EmployeeProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment

    attr_accessor :employee_role, :merge_model, :payload, :sep_id

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.special_enrollment_period = Notifier::MergeDataModels::SpecialEnrollmentPeriod.new
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

    def special_enrollment_period
      return @special_enrollment_period if defined? @special_enrollment_period
      if payload['event_object_kind'].constantize == SpecialEnrollmentPeriod
        @special_enrollment_period = employee_role.person.primary_family.special_enrollment_periods.find(payload['event_object_id'])
      else
        @special_enrollment_period = employee_role.person.primary_family.current_sep
      end
    end

    def special_enrollment_period_title
      merge_model.special_enrollment_period.title = special_enrollment_period.title
    end

    def special_enrollment_period_qle_reported_on
      merge_model.special_enrollment_period.qle_reported_on = format_date(special_enrollment_period.qle_on)
    end

    def special_enrollment_period_start_on
      merge_model.special_enrollment_period.start_on = format_date(special_enrollment_period.start_on)
    end

    def special_enrollment_period_end_on
      merge_model.special_enrollment_period.end_on = format_date(special_enrollment_period.end_on)
    end

    def special_enrollment_period_submitted_at
      merge_model.special_enrollment_period.submitted_at = format_date(special_enrollment_period.submitted_at)
    end

    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end
  end
end
