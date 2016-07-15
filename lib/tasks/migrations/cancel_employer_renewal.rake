namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal, [:fein] => [:environment] do |task, args|

    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      raise 'unable to find employer'
    end
    
    employer_profile.census_employees.each do |census_employee|    
      census_employee.aasm_state = "eligible" if census_employee.aasm_state = "employee_role_linked"    
      census_employee.save    
      puts "De-linking #{census_employee}"    
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
      organization.employer_profile.revert_application! if organization.employer_profile.may_revert_application?
    end
  end

  desc "Cancel incorrect renewal for employer"
  task :cancel_employer_incorrect_renewal, [:fein, :plan_year_start_on] => [:environment] do |task, args|

    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      puts "employer profile not found!"
      exit
    end

    plan_year_start_on = Date.strptime(args[:plan_year_start_on], "%m/%d/%Y")

    if plan_year = employer_profile.plan_years.where(:start_on => plan_year_start_on).published.first
      enrollments = enrollments_for_plan_year(plan_year)
      if enrollments.any?
        puts "Canceling employees coverage for employer #{employer_profile.legal_name}"
      end

      enrollments.each do |hbx_enrollment|
        if hbx_enrollment.may_cancel_coverage?
          hbx_enrollment.cancel_coverage!
          # Just make sure cancel propograted
        end
      end

      puts "canceling plan year for employer #{employer_profile.legal_name}"
      plan_year.cancel!
      puts "cancellation successful!"
    else
      puts "renewing plan year not found!!"
    end
  end

  desc "Cancel conversion employer renewals"
  task :conversion_employer_renewal_cancellations => :environment do 
    count = 0
    prev_canceled = 0

    employer_feins = [ 
      "200714211","510400233","521961415","530196563","270360045","522094677","231520302",
      "272141277","931169142","522062304","550864322","621469595","521021282","521795954",
      "522324745","273300538","264064164","000000028","363697513","200850720","451221231",
      "202853236","201743104","131954338","521996156","520746264","260839561","464303739",
      "204098898","521818188","042751357","521811081","521322260","521782065","521782065",
      "237400898","830353971","742994661","522312249","521498887","454741440","261332221",
      "521016137","452400752","521103582","360753125","710863908","521309304","522022029",
      "522197080","521826332","202305292","520858689","271145882","462416858","522086855",
      "521370897","453987501","530164970","464250263","530026395","237256856","611595539",
      "591640708","521442741","550825492","521766561","522167254","521826441","530176859",
      "521991811","520743373","522153746","452708794","521967581","147381250","520968193",
      "521143054","521943790","520954741","462199955","205862174","521343924","521465311",
      "521816954","020614142","521132764","521246872","307607552","272805278","522357359",
      "520978073","356007147","272035063","465185752","522315929","521989454","273585906",
      "942437024","274892667","133535334","462612890","541873351","521145355","264148393",
      "953858298","530071995","521449994"
    ]
    
    employer_feins.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)

      if employer_profile.blank?
        puts "employer profile not found!"
        return
      end

      plan_year = employer_profile.renewing_plan_year
      if plan_year.blank?
        plan_year = employer_profile.plan_years.published.detect{|py| py.start_on.year == 2016}
      end

      if plan_year.blank?
        puts "#{employer_profile.legal_name} --no renewal plan year found!!"
        prev_canceled += 1
        next
      end

      plan_year.hbx_enrollments.each do |enrollment|
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end

      employer_profile.census_employees.each do |census_employee|
        assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => plan_year.benefit_groups.map(&:id))
        assignments.each do |assignment|
          assignment.delink_coverage! if assignment.may_delink_coverage?
        end
      end

      plan_year.cancel! if plan_year.may_cancel?
      plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
      employer_profile.revert_application! if employer_profile.may_revert_application?

      count += 1
    end

    puts "Canceled #{count} employers"
    puts "#{prev_canceled} Previously Canceled employers"
  end
end

def enrollments_for_plan_year(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end
end
