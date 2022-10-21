# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# trigger rrv by year
class TriggerRrvByYear < MongoidMigrationTask
  def migrate
    assistance_year = ENV['assistance_year']
    skip = (ENV['skip'] || 0).to_i
    limit = (ENV['limit'] || 5000).to_i

    max_applications = FinancialAssistance::Application.where(:aasm_state => "determined",
                                                              :assistance_year => assistance_year,
                                                              :"applicants.is_ia_eligible" => true).distinct(:family_id)

    FinancialAssistance::Operations::Applications::Rrv::SubmitRrvSet.new.call({
                                                                                assistance_year: assistance_year,
                                                                                applications_per_event: limit,
                                                                                skip: skip,
                                                                                max_applications: max_applications.count + 100
                                                                              })
  end
end
