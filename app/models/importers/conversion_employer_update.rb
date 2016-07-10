module Importers
  class ConversionEmployerUpdate < ConversionEmployer

    def initialize(opts = {})
      super(opts)
    end
  
    def save
      organization = Organization.where(:fein => fein).first
      if organization.blank?
        errors.add(:fein, "employer don't exists with given fein")
      end

      puts "Processing Update ---#{organization.legal_name}"
      organization.legal_name = legal_name
      organization.dba = dba
      organization.office_locations = map_office_locations

      if broker_npn.present?
        broker_exists_if_specified
        br = BrokerRole.by_npn(broker_npn).first
        if br.present? && organization.employer_profile.broker_agency_accounts.where(:writing_agent_id => br.id).blank?
          organization.employer_profile.broker_agency_accounts = assign_brokers
        end
      end

      begin
        update_result = organization.save
      rescue Mongoid::Errors::UnknownAttribute
        organization.employer_profile.plan_years.each do |py|
          py.benefit_groups.first.unset(:_type)
        end
        update_result = organization.save
      end

      if update_result
        update_poc(organization.employer_profile)
      end

      propagate_errors(organization)
      return update_result
    end
  end
end