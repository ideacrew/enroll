module Notifier
  class Builders::EmployeeProfile
    attr_accessor :employee_profile, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employee_profile = resource
    end

    def notice_date
      merge_model.notice_date = format_date(TimeKeeper.date_of_record)
    end

    def first_name
      employee_profile.parent.first_name
    end

    def last_name
      employee_profile.parent.last_name
    end

    def employer_name
      employee_profile.employer_profile.legal_name
    end

    def hbx_enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        employee_profile.parent.primary_family.active_household.hbx_enrollments.find(payload['event_object_id'])
      end
    end

    def coverage_begin_date
      if hbx_enrollment.present?
        format_date(hbx_enrollment.effective_on)
      else
        earliest_coverage_begin_date
      end
    end

    def census_employee
      employee_profile.census_employee
    end

    def date_of_hire
      format_date(census_employee.hired_on)
    end

    def earliest_coverage_begin_date
      
    end

    def new_hire_oe_end_date
      format_date(new_hire_enrollment_period.max)
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end