namespace :migrations do
  desc "create missing consumer roles for dependents"
  task :change_reference_plan_for_employer => :environment do

    employer_profile = EmployerProfile.find_by_fein('383917409')
    current_plan_year = employer_profile.plan_years.published.first

    new_reference_plan = Plan.where(name: /UHC Choice Plus POS Gold 1000 A/i, market: /shop/i, active_year: 2016).first

    current_plan_year.benefit_groups.each do |benefit_group|
      benefit_group.elected_plans= [new_reference_plan]
      benefit_group.reference_plan= new_reference_plan
      benefit_group.save!
    end

    id_list = current_plan_year.benefit_groups.collect(&:_id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.each do |family|
      family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).enrolled.each do |enrollment|
        enrollment.update_attributes(:plan_id => new_reference_plan.id)
      end
    end
  end
end