require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class InverseRelations < MongoidMigrationTask
  def migrate
    field_names = %w(
      Primary_Member_First_Name
      Primary_Member_Last_Name
      Primary_Member_HBX_Id
      Primary_Member_DOB
      Dependent_First_Name
      Dependent_Last_Name
      Dependent_HBX_Id
      Dependent_DOB
      Dependent_Relationship
		)

    count = 0
    file_name = "#{Rails.root}/inverse_relations.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      families = Family.all_eligible_for_assistance

      families.each do |family|
        if family.e_case_id.present?
          begin
            primary = family.primary_applicant.person
            family.family_members.each do |member|
              inverse = false
              dependent_relation = member.relationship
              dependent = member.person

              if ["child", "grandchild", "stepchild", "ward"].include?(dependent_relation) && dependent.dob < primary.dob
                inverse = true
              elsif ["parent", "grandparent", "stepparent", "guardian"].include?(dependent_relation) && dependent.dob > primary.dob
                inverse = true
              end

              if inverse
                csv << [
                  primary.first_name,
                  primary.last_name,
                  primary.hbx_id,
                  primary.dob,
                  dependent.first_name,
                  dependent.last_name,
                  dependent.hbx_id,
                  dependent.dob,
                  dependent_relation
                ]
              end
            end
          rescue
            puts "Bad Family record #{family.id}" unless Rails.env.test?
          end
        end
			end
      puts "Total count of bad families: #{count}" unless Rails.env.test?
		end
	end
end
