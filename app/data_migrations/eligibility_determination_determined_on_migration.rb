require File.join(Rails.root, "lib/mongoid_migration_task")

class EligibilityDeterminationDeterminedOnMigration < MongoidMigrationTask
  def migrate
    begin
      field_names = %w(Enrolled_Member_HBX_ID EligibilityDetermination_bson_object_id)
      families = Family.all
      households = []
      families.each do |family|
        family.households.each do |household|
          households << household
        end
      end
      tax_households = []
      households.each do |household|
        household.tax_households.each do |tax_household|
          tax_households << tax_household
        end
      end
      eligibility_determinations = []
      tax_households.each do |tax_household|
        tax_household.eligibility_determinations.each do |eligibility_determination|
          eligibility_determinations << eligibility_determination
        end
      end
      if eligibility_determinations.blank?
        puts("No eligibility determinations present.") unless Rails.env.test?
        return
      else
        processed_count = 0
        Dir.mkdir("eligibility_determination_migration") unless File.exists?("eligibility_determination_migration_report")
        file_name = "#{Rails.root}/eligibility_determination_migration/eligibility_determination_migration_report.csv"
        CSV.open(file_name, "w", force_quotes: true) do |csv|
          csv << field_names
          eligibility_determinations.each do |determination|
            if determination.determined_on.present?
              csv << [family&.person&.hbx_id, eligibility_determinations._id.to_s]
              processed_count += 1
              # determined_ at is the proper field name
              determination.update_attributes!(determined_at: determination.determined_on)
            end
          end
        end
        puts("Total eligibility determinations with deprecated determined_on field are #{processed_count}. HBX and EligibilityDetermination MongoId outputted to: #{file_name}")
      end
    rescue => e
      e.message
    end
  end
end
