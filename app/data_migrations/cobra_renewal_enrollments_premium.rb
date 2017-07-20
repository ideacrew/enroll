require File.join(Rails.root, "lib/mongoid_migration_task")

class CobraRenewalEnrollmentsPremium< MongoidMigrationTask

  def migrate
    begin
      person_hbx_id = ENV['person_hbx_id']
      enrollment_hbx_id = ENV['enrollment_hbx_id']
      p = Person.where(hbx_id: person_hbx_id).first
      if p.present?
      hbx= p.primary_family.active_household.hbx_enrollments.where(hbx_id: enrollment_hbx_id).first
      mem= HbxEnrollmentMember.new({ applicant_id: p.primary_family.family_members.first.id, eligibility_date: hbx.effective_on, coverage_start_on: hbx.effective_on, is_subscriber: true})
      hbx.hbx_enrollment_members << mem
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