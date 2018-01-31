namespace :migrations do
  desc "update eligibility for benefit groups"
  task :update_employers_with_multiple_plan_years => :environment do

    Organization.where(:legal_name => /Georgetown University/i).each do |organization|
      organization.employer_profile.plan_years.published.each do |plan_year|
        plan_year.revert_application!
      end
    end
    
    puts "Processing AEquitas"
    published_plan_years = Organization.where(:legal_name => /AEquitas/i).first.employer_profile.plan_years.published
    valid_plan_year = published_plan_years.where("benefit_groups.title" => "AEquitas Health Insurance 2").first
    revert_invalid_plan_years(published_plan_years, valid_plan_year)

    puts "Processing Accion"
    published_plan_years = Organization.where(:legal_name => /Accion/i).first.employer_profile.plan_years.published
    valid_plan_year = published_plan_years.where("benefit_groups.title" => "Open Enrollment 2016").first
    revert_invalid_plan_years(published_plan_years, valid_plan_year)

    puts "Processing DCBA Law & Policy"
    published_plan_years = Organization.where(:legal_name => /DCBA Law & Policy/i).first.employer_profile.plan_years.published
    valid_plan_year = published_plan_years.where("benefit_groups.title" => "DCBA Benefit Package").first
    revert_invalid_plan_years(published_plan_years, valid_plan_year)
  end
end


def revert_invalid_plan_years(published_plan_years, valid_plan_year)
  published_plan_years.each do |plan_year|
    next if plan_year == valid_plan_year
    # next if has_enrollments?(plan_year)
    plan_year.revert_application!
  end
end

def has_enrollments?(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end

  if enrollments.any?
    puts "#{enrollments.size} Enrollments exists for invalid plan year under #{plan_year.employer_profile.legal_name}"
    true
  else
    false
  end
end