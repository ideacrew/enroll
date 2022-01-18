# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# rake to delete nil value evidences
class BuildFamilyDeterminations < MongoidMigrationTask
  include EventSource::Command

  def migrate
    logger = Logger.new("#{Rails.root}/log/build_determination_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    applications = FinancialAssistance::Application.where(:"applicants.evidences" => {:$exists => true}).determined
    logger.info "Total applications #{applications.count}"

    counter = 0
    applications.no_timeout.each do |application|
      counter += 1
      logger.info "processed #{counter} applications" if counter % 200 == 0

      event = event(
        "events.individual.eligibilities.application.applicant.income_evidence_updated",
        attributes: {
          gid: application.to_global_id.uri,
          build_determination: true
        }
      )

      event.success.publish if event.success?
    rescue StandardError => e
      logger.info(e.message) unless Rails.env.test?
    end
  end
end
