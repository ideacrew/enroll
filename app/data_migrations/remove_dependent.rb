require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDependent < MongoidMigrationTask
  def set_instance_variables(family, bson_id)
    @family_member = family.family_members.find(bson_id)
    @duplicate_fms = family.family_members.where(person_id: @family_member.person.id)
    @chm_fm_ids = family.active_household.coverage_households.flat_map(&:coverage_household_members).map(&:family_member_id)
    @hbx_member_fm_ids = family.active_household.hbx_enrollments.flat_map(&:hbx_enrollment_members).map(&:applicant_id)
    @th_member_ids = family.active_household.tax_households.flat_map(&:tax_household_members).map(&:applicant_id)
  end

  def fetch_dependency_type(bson_id)
    dup_fms_exists = @duplicate_fms.count > 1
    dup_chms_exists = @chm_fm_ids.include?(bson_id)
    dup_hbx_members_exists = @hbx_member_fm_ids.include?(bson_id)
    dup_th_members_exists = @th_member_ids.include?(bson_id)

    if dup_fms_exists && !dup_hbx_members_exists && !dup_th_members_exists
      dup_chms_exists ? 'chmms_dependency' : 'no_dependency'
    end
  end

  def chhm_exists_for_other_fms(bson_id)
    family_member_ids = @duplicate_fms.map(&:id) - [bson_id]
    family_member_ids.any? { |family_member_id| @chm_fm_ids.include? family_member_id }
  end

  def matching_chhm(family, bson_id)
    ch = family.active_household.coverage_households.where("coverage_household_members.family_member_id" => bson_id).first
    ch.coverage_household_members.where(family_member_id: bson_id).first
  end

  def migrate
    family_member_ids = ENV['family_member_ids'].to_s.split(',').uniq
    family_member_ids.each do |family_member_id|
      begin
        bson_id = BSON::ObjectId.from_string(family_member_id)
        family = Family.where("family_members._id" => bson_id).first
        if family.nil?
          puts "No family member found for id: #{bson_id}" unless Rails.env.test?
          next family_member_id
        end
        set_instance_variables(family, bson_id)
        dependency_type = fetch_dependency_type(bson_id)
        if dependency_type == 'no_dependency'
          @family_member.delete
          puts "Removed duplicate family member id: #{bson_id}" unless Rails.env.test?
        elsif dependency_type == 'chmms_dependency'
          # Check if there is any other Family Member record with a CoverageHouseholdMember before deleting this.
          if chhm_exists_for_other_fms(bson_id)
            chm = matching_chhm(family, bson_id)
            chm_id = chm.id
            chm.delete
            @family_member.delete
            puts "Removed duplicate coverage household member with id: #{chm_id} and family member with id: #{bson_id}" unless Rails.env.test?
          else
            puts 'Cannot destroy/delete the FamilyMember, reason: This FamilyMember does not have any other FamilyMember in the Family with CoverageHouseholdMember' unless Rails.env.test?
          end
        else
          puts 'Cannot destroy/delete the FamilyMember' unless Rails.env.test?
        end
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
  end
end
