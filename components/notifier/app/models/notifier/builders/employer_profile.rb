module Notifier
  class Builders::EmployerProfile
    attr_reader :employer_profile, :merge_model

    def initialize
      @merge_model = Notifier::MergeDataModels::EmployerProfile.new
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

    def plan_year_present?
      if plan_year.present?
        if merge_model.plan_year.blank?
          merge_model.plan_year = Notifier::MergeDataModels::PlanYear.new
        end
        true
      else
        false
      end
    end

    def plan_year
      employer_profile.plan_years.last
    end

    def plan_year_end_on
      merge_model.plan_year.end_on = plan_year.end_on if plan_year_present?
    end

    def plan_year_start_on
      merge_model.plan_year.start_on = plan_year.start_on if plan_year_present?
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
  end
end
