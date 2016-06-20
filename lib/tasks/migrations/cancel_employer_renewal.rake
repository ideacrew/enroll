namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal, [:fein] => [:environment] do |task, args|
    
    employer_profile = EmployerProfile.find_by_fein(args[:fein])

      if employer_profile.blank?
        raise 'unable to find employer'
      end

      puts "Processing #{employer_profile.legal_name}"
      organizations = Organization.where(fein: args[:fein])
      organizations.each do |organization|
        renewing_plan_year = organization.employer_profile.plan_years.renewing.first
        if renewing_plan_year.present?
          enrollments = enrollments_for_plan_year(renewing_plan_year)
          enrollments.each do |enrollment|
            enrollment.cancel_coverage! 
          end

          puts "found renewing plan year for #{organization.legal_name}---#{renewing_plan_year.start_on}"
          renewing_plan_year.cancel_renewal! if renewing_plan_year.may_cancel_renewal?
        end
      end
   end
 end


def enrollments_for_plan_year(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end
end

