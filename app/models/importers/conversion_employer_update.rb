module Importers
  class ConversionEmployerUpdate < ConversionEmployer

    def initialize(opts = {})
      super(opts)
    end
  
    def save
      begin
        organization = Organization.where(:fein => fein).first
        if organization.blank?
          errors.add(:fein, "employer don't exists with given fein")
        end
        puts "Processing Update #{fein}---Data Sheet# #{legal_name}---Enroll App# #{organization.legal_name}"
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

        broker = find_broker
        general_agency = find_ga

        if broker.present? && general_agency.present?
      
          general_agency_account = organization.employer_profile.general_agency_accounts.where({
            :general_agency_profile_id => general_agency.id,
            :broker_role_id => broker.id
            }).first

          if general_agency_account.present?

            organization.employer_profile.general_agency_accounts.each do |account|
              if (account.id != general_agency_account.id && account.active?)
                account.terminate! if account.may_terminate?
              end            
            end

            general_agency_account.update_attributes(:aasm_state => 'active') if general_agency_account.inactive?
          else
            if new_account = assign_general_agencies.first
              organization.employer_profile.general_agency_accounts.each{|ac| ac.terminate! if ac.may_terminate? }
              organization.employer_profile.general_agency_accounts << new_account
            end
          end
        end

        update_result = organization.save
      rescue Mongoid::Errors::UnknownAttribute
        organization.employer_profile.plan_years.each do |py|
          py.benefit_groups.each{|bg| bg.unset(:_type) }
        end
        update_result = organization.save
      rescue Exception => e
        puts "FAILED.....#{e.to_s}"
      end

      begin
        if update_result
          update_poc(organization.employer_profile)
        end
      rescue Exception => e
        puts "FAILED.....#{e.to_s}"
      end

      if organization
        propagate_errors(organization)
      end
      return update_result
    end
  end
end
