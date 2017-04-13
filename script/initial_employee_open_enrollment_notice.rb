date = TimeKeeper.date_of_record.yesterday

census_employees = CensusEmployee.where(:"created_at" => {"$gte" => date}).eligible

CSV.open("initial_employee_open_enrollment_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv","w") do |csv|
  csv << ["Full Name", "Email", "Hired on", "Employer"]
  begin
    census_employees.each do |ce|
      if ce.hired_on <= date
        Invitation.invite_initial_employee_for_open_enrollment!(ce)
      elsif ce.hired_on > date
        Invitation.invite_future_employee_for_open_enrollment!(ce)
      end
      csv << [ce.full_name, ce.email_address, ce.hired_on, ce.employer_profile.legal_name]
    end
  rescue Exception => e
    puts "#{Unable to deliver to ce.full_name due to} --- #{e}" unless Rails.env.test?
  end
end