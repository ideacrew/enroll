# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# trigger rrv by year
class TriggerRrvByYear < MongoidMigrationTask
  def migrate
    assistance_year = ENV['assistance_year']
    skip = (ENV['skip'] || 0).to_i
    limit = (ENV['limit'] || 5000).to_i

    family_ids = FinancialAssistance::Application.where(aasm_state: "determined", assistance_year: assistance_year, :"applicants.is_ia_eligible" => true).distinct(:family_id)
    all_families = Family.where(:_id.in => family_ids)

    if all_families.count > 0
      while skip < all_families.count
        criteria = all_families.skip(skip).limit(limit)
        FinancialAssistance::Operations::TestApplications::Rrv::CreateRrvRequest.new.call({families: criteria, assistance_year: assistance_year})
        puts "Total number of records processed #{skip + criteria.pluck(:id).length}"
        skip += limit
      end
    else
      puts "No Determined applications with ia_eligible applicants in the year #{assistance_year}"
    end
  end
end
