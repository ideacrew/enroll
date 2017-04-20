date = TimeKeeper.date_of_record
organizations = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:aasm_state.in => ["enrolling", "renewing_enrolling"], :open_enrollment_end_on => date+2.days}})
organizations.each do |org|
  plan_year = org.employer_profile.plan_years.where(:aasm_state.in => ["enrolling", "renewing_enrolling"]).first
  #exclude congressional employees
  next if plan_year.benefit_groups.any?{|bg| bg.is_congress?}
  census_employees = org.employer_profile.census_employees
  census_employees.each do |ce|
    begin
      #exclude new hires
      next if (ce.new_hire_enrollment_period.cover?(date) || ce.new_hire_enrollment_period.first > date)
      ShopNoticesNotifierJob.perform_later(ce.id.to_s, "employee_open_enrollment_reminder")
    rescue Exception => e
      puts "Unable to deliver open enrollment reminder notice to #{ce.full_name} due to #{e}" unless Rails.env.test?
    end
  end
end