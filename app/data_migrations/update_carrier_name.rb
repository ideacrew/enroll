require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierName < MongoidMigrationTask
  def migrate
    puts "*"*80 unless Rails.env.test?
    puts "Updating carrier legal name in old model." unless Rails.env.test?

    org = Organization.where(fein: ENV["fein"]).last
    org.update_attributes(legal_name: ENV["name"]) if org.present?

    puts "Successfully updated carrier legal name in old model -> #{org.legal_name}" unless Rails.env.test?

    puts "Updating carrier legal name in new model." unless Rails.env.test?

    eo = ::BenefitSponsors::Organizations::Organization.where(fein: ENV["fein"]).first
    eo.update_attributes(legal_name: ENV["name"]) if eo.present?

    puts "Successfully updated carrier legal name in new model -> #{org.legal_name}" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end
