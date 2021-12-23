# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# rake to delete nil value evidences
class MigrateEvidences < MongoidMigrationTask

  def migrate
    logger = Logger.new("#{Rails.root}/log/evidences_migration_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    applications = FinancialAssistance::Application.where(:"applicants.evidences" => {:$exists => true}).determined
    logger.info "Total applications #{applications.count}"

    counter = 0
    applications.no_timeout.each do |application|
      counter += 1
      logger.info "processed #{counter} applications" if counter % 200 == 0
      application.applicants.each do |applicant|
        result = ::Operations::MigrateEvidences.new.call(applicant: applicant)
        if result.failure?
          errors = result.failure.is_a?(Dry::Validation::Result) ? result.failure.errors.to_h : result.failure
          logger.info "Error: unable to migrate evidences for applicant: #{applicant.id} in application #{application.id} due to #{errors}"
        end
      end
    rescue StandardError => e
      logger.info(e.message) unless Rails.env.test?
    end
  end
end
