module Notifier
  class Builders::EmployeeProfile
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker
    include Notifier::Builders::Enrollment

    attr_accessor :employee_role, :merge_model, :payload, :qle_title, :qle_event_on, :qle_reporting_deadline

    def initialize
      data_object = Notifier::MergeDataModels::EmployeeProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      data_object.enrollment = Notifier::MergeDataModels::Enrollment.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.qle = Notifier::MergeDataModels::QualifyingLifeEventKind.new
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

    def qle
      return @qle if defined? @qle
      if payload['event_object_kind'].constantize == QualifyingLifeEventKind
        @qle = QualifyingLifeEventKind.find(payload['event_object_id'])
      end
    end

    def qle_title
      merge_model.qle.title = qle.blank? ? payload['qle_title'] : qle.title
    end

    def qle_start_on
      return if qle.blank?
      merge_model.qle.start_on = qle.start_on
    end

    def qle_end_on
      return if qle.blank?
      merge_model.qle.end_on = qle.end_on
    end

    def qle_event_on
      return if qle.blank?
      merge_model.qle.event_on = qle.event_on.blank? ? Date.strptime(payload['qle_event_on'], '%m/%d/%Y') : qle.event_on
    end

    def qle_reported_on
      return if qle.blank?
      merge_model.qle.reported_on = qle.updated_at
    end

    def qle_reporting_deadline
      return if qle.blank? && payload['qle_reporting_deadline'].nil?
      merge_model.qle.reporting_deadline = Date.strptime(payload['qle_reporting_deadline'], '%m/%d/%Y')
    end
  end
end
