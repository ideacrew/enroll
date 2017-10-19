module Notifier
  class Builders::EmployeeProfile
    include ActionView::Helpers::NumberHelper

    attr_accessor :employee_role, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Plan.new
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

    def current_plan_year
      return @current_plan_year if defined? @current_plan_year
      if payload['event_object_kind'].constantize == PlanYear
        plan_year = employer_profile.plan_years.find(payload['event_object_id'])
      end

      if plan_year.blank? && enrollment.present?
        if enrollment.benefit_group
          plan_year = enrollment.benefit_group.plan_year
        end
      end

      if plan_year.present? && !plan_year.is_renewing?
        @current_plan_year = plan_year
      end
    end

    def renewal_plan_year
      return @renewal_plan_year if defined? @renewal_plan_year
      if payload['event_object_kind'].constantize == PlanYear
        plan_year = employer_profile.plan_years.find(payload['event_object_id'])
      end

      if plan_year.blank? && enrollment.present?
        if enrollment.benefit_group
          plan_year = enrollment.benefit_group.plan_year
        end
      end

      if plan_year.present? && plan_year.is_renewing?
        @renewal_plan_year = plan_year
      end
    end

    def renewal_plan_year_start_date
      start_date = renewal_plan_year.start_on if renewal_plan_year.present?
      if start_date.blank? && current_plan_year.present?
        start_date = current_plan_year.start_on.next_year
      end

      merge_model.renewal_plan_year_start_date = format_date(start_date)
    end

    def renewal_plan_year_end_date
      end_date = renewal_plan_year.end_on if renewal_plan_year.present?
      if end_date.blank? && current_plan_year.present?
        end_date = current_plan_year.end_on.next_year
      end

      merge_model.renewal_plan_year_end_date = format_date(end_date)
    end

    def current_plan_year_start_date
      start_date = current_plan_year.start_on if current_plan_year.present?
      if start_date.blank? && renewal_plan_year.present?
        start_date = renewal_plan_year.start_on.prev_year
      end

      merge_model.current_plan_year_start_date = format_date(start_date)
    end

    def current_plan_year_end_date
      end_date = current_plan_year.end_on if current_plan_year.present?
      if end_date.blank? && renewal_plan_year.present?
        end_date = renewal_plan_year.end_on.prev_year
      end

      merge_model.current_plan_year_end_date = format_date(end_date)
    end

    def current_coverage_year
      year = current_plan_year.year if current_plan_year.present?
      if renewal_plan_year.present?
        year = renewal_plan_year.year - 1
      end
      merge_model.current_coverage_year = year
    end

    def renewal_coverage_year
      year = renewal_plan_year.year if renewal_plan_year.present?
      if current_plan_year.present?
        year = current_plan_year.year + 1
      end
      merge_model.renewal_coverage_year = year
    end

    def employer_profile
      employee_role.employer_profile
    end

    def broker_agency_account
      employer_profile.active_broker_agency_account
    end

    def broker
      broker_agency_account.writing_agent.parent if broker_agency_account.present?
    end

    def broker_present?
      if broker.present?
        if merge_model.broker.blank?
          merge_model.broker = Notifier::MergeDataModels::Broker.new
        end
        true
      else
        false
      end
    end

    def broker_primary_fullname
      if broker_present?
        merge_model.broker.primary_fullname = broker.full_name
      end
    end

    def broker_organization
      if broker_agency_account.present?
        merge_model.broker.organization = broker_agency_account.legal_name
      end
    end

    def broker_phone
      if broker_present?
        merge_model.broker.phone = broker.work_phone_or_best
      end
    end

    def broker_email
      if broker_present?
        merge_model.broker.email = broker.work_email_or_best
      end
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end