# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class FixEdSourceNonCuramCases < MongoidMigrationTask
  # Assuming the objects with source 'Admin_Script' that got created
  # on both 10/31 and 11/1 of any year are via Renewals and all
  # the others with source 'Admin_Script' via Create Eligibility tool.
  def object_created_by_renewals(eligibility_determination)
    date = eligibility_determination.created_at
    return if date.nil?

    (date.month == 11 && date.day == 1) || (date.month == 10 && date.day == 31)
  end

  def migrate
    field_names = %w[person_hbx_id ed_object_id source e_pdc_id]
    file_name = "#{Rails.root}/list_of_ed_object_ids_for_non_curam_cases.csv"

    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names

      Family.where(:"households.tax_households.eligibility_determinations.source".in => ['Admin_Script', nil]).inject([]) do |_dummy, family|
        person = family.primary_person
        family.active_household.tax_households.where(:"eligibility_determinations.source".in => ['Admin_Script', nil]).each do |thh|
          thh.eligibility_determinations.where(:source.in => ['Admin_Script', nil]).each do |ed|
            if ed.source == 'Admin_Script' && object_created_by_renewals(ed)
              ed.update_attributes!(source: 'Renewals')
            else
              ed.update_attributes!(source: 'Admin')
            end
            csv << [person.hbx_id, ed.id, ed.source, ed.e_pdc_id]
          end
        end
      rescue StandardError => e
        puts e.message
      end
    end
  end
end
