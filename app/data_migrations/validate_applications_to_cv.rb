# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# validate applications for cv3 payload
class ValidateApplicationsToCv < MongoidMigrationTask
  def migrate
    logger = Logger.new("#{Rails.root}/log/imported_application_validate_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

    calender_year = ENV['calender_year']

    families = ::FinancialAssistance::Application.by_year(calender_year).where(:aasm_state.nin => ['determined']).distinct(:family_id) #renewal_eligible.distinct(:family_id)
    families.each_with_index do |family_id, index|
      logger.info "Processing family_id: #{family_id}, index: #{index}"

      applications_by_family = ::FinancialAssistance::Application.where(family_id: family_id)
      application = applications_by_family.by_year(calender_year).where(:aasm_state.nin => ['determined']).last # renewal_eligible.created_asc.last

      if application.present?
        result = FinancialAssistance::Operations::Applications::MedicaidGateway::ValidateApplicationToCv.new.call(application_id: application.id)

        if result.success?
          logger.info "Success: generated cv3 payload successuflly for application_id: #{application.id}"
        else
          errors = if result.failure.is_a?(Dry::Validation::Result)
                     result.failure.errors.to_h
                   else
                     result.failure
                   end

          logger.info "Error: Validation failed for application_id: #{application.id} due to #{errors}"
        end
      else
        logger.info "Error: Renewal eligible application not found for family_id: #{family_id}"
      end
    end
  end
end
