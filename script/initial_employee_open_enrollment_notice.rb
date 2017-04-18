date = TimeKeeper.date_of_record

census_employees = CensusEmployee.where(:"hired_on" => date)

census_employees.each do |ce|
  begin
    if ce.has_benefit_group_assignment?
      plan_year = ce.active_benefit_group_assignment.benefit_group.plan_year
      Invitation.invite_initial_employee_for_open_enrollment!(ce) if (ce.hired_on == date && plan_year.employees_are_matchable?)
    end
  rescue Exception => e
    puts "Unable to deliver to #{ce.full_name} due to --- #{e}" unless Rails.env.test?
  end
end