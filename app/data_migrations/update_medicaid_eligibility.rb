require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateMedicaidEligibility < MongoidMigrationTask
  def migrate
    begin
      primary_id = (ENV['primary_id']).to_s
      dependents_ids = (ENV['dependents_ids']).to_s
      dependents_ids = dependents_ids.split(',')
      eligiblility_year = (ENV['eligiblility_year']).to_s
      person = Person.where(hbx_id: primary_id).first

      family = person.primary_family
      if person.present? && family.present?

        people_ids = dependents_ids.inject([]) do |bson_ids, dep_id|
          dep_person = Person.where(hbx_id: dep_id).first
          bson_ids << dep_person.id if dep_person.present?
        end

        valid_tax_household = family.active_household.tax_households.active_tax_household.tax_household_with_year(eligiblility_year.to_i).sort_by(&:effective_starting_on).first

        family_member_ids = people_ids.inject([]) do |fm_ids, person_id|
          fm_ids << family.family_members.where(person_id: person_id).first.id
        end

        family_member_ids.each do |fm_id|
          tax_hh_member = valid_tax_household.tax_household_members.where(applicant_id: fm_id).first

          if tax_hh_member.present?
            tax_hh_member.update_attributes!(is_medicaid_chip_eligible: true)
            person_hbx_id = family.family_members.where(id: fm_id).first.person.hbx_id
            puts "Updated Medicaid Eligibility for person with hbx_id: #{person_hbx_id}" unless Rails.env.test?
          end
        end
      end
    rescue
      puts "Bad Primary Person Record with hbx_id: #{primary_id}" unless Rails.env.test?
    end
  end
end