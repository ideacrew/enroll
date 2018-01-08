require File.join(Rails.root, "lib/mongoid_migration_task")
class AddBenefitGroupId < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id']
      hbx_enrollments = Person.where(:hbx_id => hbx_id).first.try(:primary_family).try(:active_household).try(:hbx_enrollments)
      if hbx_enrollments.present?
        employer_sponsored_hbx_enrollment = hbx_enrollments.where(kind:'employer_sponsored').first
        hbx_enroll_first = hbx_enrollments.first
        if hbx_enroll_first.benefit_group.nil? and employer_sponsored_hbx_enrollment.present? and employer_sponsored_hbx_enrollment.benefit_group_id.present?
          hbx_enroll_first.benefit_group_id = employer_sponsored_hbx_enrollment.benefit_group_id
          if hbx_enroll_first.valid?
            hbx_enroll_first.save!
            hbx_enroll_first.hbx_id
          end
        end  
      end
    rescue => e
      puts "#{e}"
    end
  end
end