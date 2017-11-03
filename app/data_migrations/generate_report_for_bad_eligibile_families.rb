require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class GenerateReportForBadEligibileFamilies < MongoidMigrationTask
  def migrate

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/generate_report_for_bad_eligibile_families.csv"

    field_names  = %w(
          Family_e_case_id
          PrimaryPerson_FN
          PrimaryPerson_FN
          PrimaryPerson_Hbx_ID
         )
    count = 0

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      Family.all.all_eligible_for_assistance.each do |family|
        begin
          primary_person = family.primary_applicant.person
          tax_household = family.active_household.latest_active_tax_household
          if tax_household.latest_eligibility_determination.max_aptc.to_f > 0.0
            #We don't read these fields from the Curam response payload(is_medicaid_chip_eligible and is_without_assistance).
            if !tax_household.tax_household_members.map(&:is_ia_eligible).include?(true)
              csv << [
                family.e_case_id,
                primary_person.first_name,
                primary_person.last_name,
                primary_person.hbx_id
              ]
              count += 1
              puts "Primary_Person_hbx_id: #{primary_person.hbx_id}" unless Rails.env.test?
            end
          end
        rescue => e
          puts "Bad Family Record, error: #{e}" unless Rails.env.test?
        end
      end
      puts "Total number of Families: #{count}" unless Rails.env.test?
    end
  end
end
