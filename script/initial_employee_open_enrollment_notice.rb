date = TimeKeeper.date_of_record.yesterday

census_employees = CensusEmployee.where(:"created_at" => {"$gte" => date}).eligible

  census_employees.each do |ce|
    begin
      if ce.hired_on <= date
        Invitation.invite_initial_employee_for_open_enrollment!(ce)
      elsif ce.hired_on > date
        Invitation.invite_future_employee_for_open_enrollment!(ce)
      end
    rescue Exception => e
      puts "Unable to deliver to #{ce.full_name} due to --- #{e}" unless Rails.env.test?
    end
  end
