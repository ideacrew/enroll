require File.join(Rails.root, "lib/mongoid_migration_task")

class CobraRenewalEnrollmentsPremium< MongoidMigrationTask

  def migrate
    begin
      hbx_id = ENV['hbx_id']
      hbx_id1 = ENV['hbx_id1']
      p = Person.where(hbx_id: hbx_id).first
      if p.present?
      hbx= p.primary_family.active_household.hbx_enrollments.where(hbx_id: hbx_id1).first
      mem= HbxEnrollmentMember.new({ applicant_id: p.primary_family.family_members.first.id, eligibility_date: hbx.effective_on, coverage_start_on: hbx.effective_on, is_subscriber: true})
      hbx.hbx_enrollment_members << mem
      puts hbx.hbx_enrollment_members.count
      cost=PlanCostDecorator.new(hbx.plan, hbx , hbx.benefit_group, hbx.benefit_group.reference_plan)
      puts "cobra renewal enrollments premium is changed" unless Rails.env.test?
    else
      puts "No Person Found" unless Rails.env.test?
    end
    rescue => e
      puts "#{e}" unless Rails.env.test?
    end
  end 
end