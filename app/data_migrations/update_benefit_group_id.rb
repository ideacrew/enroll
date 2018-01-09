require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateBenefitGroupId < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id']
      benefit_group_id = ENV['benefit_group_id'].to_s
      hbx_enrollments = Person.where(:hbx_id => hbx_id).first.try(:primary_family).try(:active_household).try(:hbx_enrollments)
      if hbx_enrollments.present?
         hbx_enroll_first = hbx_enrollments.first
        if hbx_enroll_first.benefit_group.nil?
          hbx_enroll_first.benefit_group_id = benefit_group_id
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