require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfile < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    @logger = Logger.new(STDOUT)
    exist_fein = ENV['exist_fein'].to_s

    service = BenefitSponsors::Services::UpdateBrokerAgencyService.new({fein: exist_fein})

    case action

    when "update_fein"
      new_fein = ENV['new_fein'].to_s
      @logger.info "Trying to update fein from #{exist_fein} to #{new_fein}"
      service.update_organization_attributes({fein: new_fein})
      @logger.info "Updated to fein #{new_fein}"

    when "corporate_npn"
      new_npn = ENV['corporate_npn'].to_s
      @logger.info "Trying to update corporate_npn"
      service.update_broker_agency_attributes({corporate_npn: new_npn})
      @logger.info "Updated corporate NPN is #{new_npn}"

    when "update_person"
      person_hbx_id = ENV['hbx_id'].to_s
      @logger.info "Trying to associate broker agency staff role to person with hbx_id #{person_hbx_id}"
      service.update_broker_profile_id({hbx_id: person_hbx_id})
      @logger.info "Updated person broker agency staff roles"

    else
      @logger.warn "Unknown Action found"
    end
  end
end
