module Notifier
  class Builders::EmployeeProfile

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper
    include Notifier::Builders::BenefitApplication
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment

    attr_accessor :employee_role, :merge_model, :payload, :event_name, :sep_id
    attr_accessor :qle_title, :qle_event_on, :qle_reporting_deadline

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.dental_enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.benefit_application = Notifier::MergeDataModels::BenefitApplication.new
      data_object.census_employee = Notifier::MergeDataModels::CensusEmployee.new
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
      mailing_address =
        if employee_role.person.mailing_address
          employee_role.person.mailing_address
        elsif employee_role.census_employee
          employee_role.census_employee.address
        end

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

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = format_date(Settings.aca.individual_market.upcoming_open_enrollment.start_on)
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = format_date(Settings.aca.individual_market.upcoming_open_enrollment.end_on)
    end

    def email
      merge_model.email = employee_role.person.work_email_or_best if employee_role.present?
    end

    def employer_profile
      employee_role.employer_profile
    end

    def employer_name
      merge_model.employer_name = employer_profile.legal_name
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

    def coverage_terminated_on_plus_30_days
      merge_model.coverage_terminated_on_plus_30_days = format_date(census_employee_record.coverage_terminated_on + 30.days)
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

    def has_parent_enrollment?
      bgas = []
      bgas << census_employee_record.active_benefit_group_assignment
      bgas << census_employee_record.renewal_benefit_group_assignment
      waiver_enr = bgas.compact.flat_map(&:hbx_enrollments).select {|en| HbxEnrollment::WAIVED_STATUSES.include?(en.aasm_state)}.first
      return false if waiver_enr.blank?
      waiver_enr.parent_enrollment.present?
    end

    def has_multiple_enrolled_enrollments?
      enrolled_enrollments.size > 1
    end

    def has_health_enrolled_enrollment?
      enrolled_enrollments.by_coverage_kind("health").first.present?
    end

    def has_dental_enrolled_enrollment?
      enrolled_enrollments.by_coverage_kind("dental").first.present?
    end

    def enrolled_enrollments
      employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.enrolled
    end

    def census_employee_health_and_dental_enrollment?
      census_employee_health_enrollment? && census_employee_dental_enrollment?
    end

    def latest_terminated_enrollment(coverage_kind)
      enrollment = employee_role.person.primary_family.active_household.hbx_enrollments.shop_market.by_coverage_kind("health").where(:aasm_state.in => ["coverage_termination_pending", "coverage_terminated"]).detect do |hbx|
        census_employee_record.employment_terminated_on <= hbx.terminated_on
      end
      enrollment
    end

    def latest_terminated_health_enrollment
      latest_terminated_enrollment("health")
    end

    def latest_terminated_dental_enrollment
      latest_terminated_enrollment("dental")
    end

    def census_employee_latest_terminated_health_enrollment_plan_name
      if latest_terminated_health_enrollment.present?
        merge_model.census_employee.latest_terminated_health_enrollment_plan_name = latest_terminated_health_enrollment.product.name
      end
    end

    def census_employee_latest_terminated_dental_enrollment_plan_name
      if latest_terminated_dental_enrollment.present?
        merge_model.census_employee.latest_terminated_dental_enrollment_plan_name = latest_terminated_dental_enrollment.product.name
      end
    end

    def dependents_name
      names = []
      payload["notice_params"]["dep_hbx_ids"].each do |dep_id|
        names << Person.where(hbx_id: dep_id).first.full_name
      end
      merge_model.dependents_name = names.join(", ")
    end

    def dependent_termination_date
      merge_model.dependent_termination_date = format_date(TimeKeeper.date_of_record.end_of_month)
    end
    
    # Using same merge model for special enrollment period and qualifying life event kind.
    def special_enrollment_period
      return @special_enrollment_period if defined? @special_enrollment_period
      if payload['event_object_kind'].constantize == SpecialEnrollmentPeriod
        @special_enrollment_period = employee_role.person.primary_family.special_enrollment_periods.find(payload['event_object_id'])
      elsif payload['event_object_kind'].constantize == QualifyingLifeEventKind
        @special_enrollment_period = QualifyingLifeEventKind.find(payload['event_object_id'])
      else
        @special_enrollment_period = employee_role.person.primary_family.current_sep
      end
    end

    def special_enrollment_period_event_on
      merge_model.special_enrollment_period.event_on = payload['notice_params'] && payload['notice_params']['qle_event_on'] || format_date(special_enrollment_period.event_on)
    end

    def future_sep?
      Date.strptime(special_enrollment_period_event_on, '%m/%d/%Y').future?
    end

    def special_enrollment_period_title
      merge_model.special_enrollment_period.title = payload['notice_params'] && payload['notice_params']['qle_title'] || special_enrollment_period.title
    end

    def special_enrollment_period_qle_reported_on
      merge_model.special_enrollment_period.qle_reported_on = (special_enrollment_period.present? && special_enrollment_period.qle_on.present?) ? format_date(special_enrollment_period.qle_on) : format_date(TimeKeeper.date_of_record)
    end

    def special_enrollment_period_start_on
      if special_enrollment_period.present? && special_enrollment_period.start_on.present?
        merge_model.special_enrollment_period.start_on = format_date(special_enrollment_period.start_on)
      end
    end

    def special_enrollment_period_end_on
      merge_model.special_enrollment_period.end_on = format_date(special_enrollment_period.end_on)
    end

    def special_enrollment_period_submitted_at
      merge_model.special_enrollment_period.submitted_at = format_date(special_enrollment_period.submitted_at) if special_enrollment_period.submitted_at.present?
    end

    def special_enrollment_period_reporting_deadline
      deadline = payload['notice_params']['qle_reporting_deadline']
      merge_model.special_enrollment_period.reporting_deadline = deadline
    end

    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end
  end
end
