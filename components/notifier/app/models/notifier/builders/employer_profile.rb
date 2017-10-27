module Notifier
  class Builders::EmployerProfile
    include Notifier::Builders::PlanYear
    include Notifier::Builders::Broker

    attr_accessor :employer_profile, :merge_model, :payload
    
    def initialize
      data_object = Notifier::MergeDataModels::EmployerProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.plan_year = Notifier::MergeDataModels::PlanYear.new
      data_object.broker = Notifier::MergeDataModels::Broker.new
      @merge_model = data_object
    end

    def resource=(resource)
      @employer_profile = resource
    end

    def append_contact_details
      if employer_profile.staff_roles.present?
        merge_model.first_name = employer_profile.staff_roles.first.first_name
        merge_model.last_name = employer_profile.staff_roles.first.last_name
      end

      office_address = employer_profile.organization.primary_office_location.address
      if office_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: office_address.address_1,
          street_2: office_address.address_2,
          city: office_address.city,
          state: office_address.state,
          zip: office_address.zip
          })
      end
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def employer_name
      merge_model.employer_name = employer_profile.legal_name
    end

    def current_plan_year
      return @current_plan_year if defined? @current_plan_year
      if payload['event_object_kind'].constantize == PlanYear
        plan_year = employer_profile.plan_years.find(payload['event_object_id'])
        if plan_year.is_renewing?
          @current_plan_year = employer_profile.plan_years.detect{|py| py.is_published? && py.start_on == plan_year.start_on.prev_year}
        else
          @current_plan_year = plan_year
        end
      end
    end

    def renewal_plan_year
      return @renewal_plan_year if defined? @renewal_plan_year
      if payload['event_object_kind'].constantize == PlanYear
        plan_year = employer_profile.plan_years.find(payload['event_object_id'])
        if plan_year.is_renewing?
          @renewal_plan_year = plan_year
        else
          @renewal_plan_year = employer_profile.plan_years.detect{|py| py.is_renewing? && py.start_on == plan_year.start_on.next_year}
        end
      end
    end

    def plan_year_renewal_py_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_start_date = format_date(renewal_plan_year.start_on) 
      end
    end

    def plan_year_renewal_py_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_end_date = format_date(renewal_plan_year.end_on)
      end
    end

    def plan_year_current_py_oe_start_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_start_date = format_date(current_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_current_py_oe_end_date
      if current_plan_year.present?
        merge_model.plan_year.current_py_oe_end_date = format_date(current_plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_renewal_py_oe_start_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_start_date = format_date(renewal_plan_year.open_enrollment_start_on)
      end
    end

    def plan_year_renewal_py_oe_end_date
      if renewal_plan_year.present?
        merge_model.plan_year.renewal_py_oe_end_date = format_date(renewal_plan_year.open_enrollment_end_on)
      end
    end

    def plan_year_renewal_py_submit_soft_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_soft_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.application_submission_soft_deadline))
      end
    end

    def plan_year_renewal_py_submit_due_date
      if renewal_plan_year.present?
        prev_month = renewal_plan_year.start_on.prev_month
        merge_model.plan_year.renewal_py_submit_due_date = format_date(Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month))
      end
    end

    def plan_year_binder_payment_due_date
      if current_plan_year.present?
        merge_model.plan_year.renewal_py_submit_due_date = format_date(PlanYear.map_binder_payment_due_date_by_start_on(current_plan_year.start_on))
      end
    end

    def format_date(date)
      return if date.blank?
      date.strftime("%m/%d/%Y")
    end


    # Following date fileds are defined to allow business enter tokens like <Current Plan Year END On Date, MM/DD/YYYY, + 60 Days>
    # attribute :current_py_start_on, Date
    # attribute :current_py_end_on, Date
    # attribute :renewal_py_start_on, Date
    # attribute :renewal_py_end_on, Date
  end
end
