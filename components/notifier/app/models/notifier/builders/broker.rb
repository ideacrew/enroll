module Notifier
  module Builders::Broker
    def broker_agency_account
      employer_profile.active_broker_agency_account
    end

    def broker
      broker_agency_account.writing_agent.parent if broker_agency_account.present?
    end

    def broker_present?
      if broker.blank?
        merge_model.broker = nil
        false
      else
        true
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