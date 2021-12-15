# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# rake to delete nil value evidences
class DeleteNilEvidences < MongoidMigrationTask

  def migrate
    nil_evidence_applications = FinancialAssistance::Application.where(:"applicants.evidences" => {:$exists => true}, :aasm_state => "determined", :"applicants.evidences.key" => {:$eq => nil })

    nil_evidence_applications.no_timeout.each do |application|
      application.applicants.flat_map(&:evidences).each do |evidence|
        evidence.destroy if evidence.key.nil?
      end
      application.save!
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
