# # frozen_string_literal: true

# # rails runner app/data_migrations/fix_ed_source_curam_cases.rb -e production
# require File.join(Rails.root, 'lib/mongoid_migration_task')
# # This migration is to set a field source on EligibilityDetermination
# # model to dictate what is the source of this object's creation.

# field_names = %w[person_hbx_id ed_object_id source e_pdc_id]
# file_name = "#{Rails.root}/list_of_ed_object_ids_for_curam_cases.csv"

# CSV.open(file_name, 'w', force_quotes: true) do |csv|
#   csv << field_names

#   Family.where(:"households.tax_households.eligibility_determinations.e_pdc_id".ne => nil).inject([]) do |_dummy, family|
#     person = family.primary_person
#     family.active_household.tax_households.where(:"eligibility_determinations.e_pdc_id".ne => nil).each do |thh|
#       thh.eligibility_determinations.where(:e_pdc_id.ne => nil).each do |ed|
#         next ed if ed.e_pdc_id.include?('MANUALLY')

#         ed.update_attributes!(source: 'Curam')
#         csv << [person.hbx_id, ed.id, ed.source, ed.e_pdc_id]
#       end
#     end
#   rescue StandardError => e
#     puts e.message
#   end
# end
