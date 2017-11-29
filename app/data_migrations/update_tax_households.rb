require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateTaxHouseholds < MongoidMigrationTask
  def migrate
    thh_year = ENV['tax_household_year'].to_i # This is the Year for which you are 're-activating' the THH.
    if thh_year == TimeKeeper.date_of_record.year
      field_names = %w(
            family_id
            hbx_id
            reactivated_tax_household_id
            tax_household_starting_on
            tax_household_ending_on_before_update
            tax_household_ending_on_after_update
            updated_at
          )

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/families_with_thh_updated.csv"
      count = 0
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        Family.all.all_assistance_receiving.each do |family|
          begin
            latest_thh = family.active_household.tax_households.tax_household_with_year(thh_year).sort_by(&:created_at).last
            tax_household_ending_on_before_update = latest_thh.effective_ending_on
            latest_thh.update_attributes!(effective_ending_on: nil)

            csv << [
                family.id,
                family.primary_applicant.person.hbx_id,
                latest_thh.id,
                latest_thh.effective_starting_on,
                tax_household_ending_on_before_update,
                latest_thh.effective_ending_on,
                TimeKeeper.datetime_of_record
            ]
            count+=1

          rescue => e
            puts "Bad Family Record with id: #{family.id}" unless Rails.env.test?
          end
        end
      end
      puts "updated #{count} families" unless Rails.env.test?
    else
      puts "cannot activate THH, which is not the current year" unless Rails.env.test?
    end
  end
end
