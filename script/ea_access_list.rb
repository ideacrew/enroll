  require 'csv'

  batch_size = 500
  offset = 0
  user_count = User.count

  file_name = "#{Rails.root}/ea_access_list_#{DateTime.now.strftime("%m_%d_%Y_%H_%M")}.csv"

  processed_count = 0

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << ["User Id", "User's Name", "OIM ID", "Email" ,"Role", "User Record Created Date", "Last Login Date", "Last Portal Visited", "Role Start on(ER-EE/ER-BA/HBX Staff)", "Role Termination Date(ER-EE/ER-BA/HBX Staff)"]
    while offset < user_count
      User.offset(offset).limit(batch_size).each do |user|
        if processed_count % 1000 == 0
          puts "processed #{processed_count}" unless Rails.env.test?
        end
        begin
          person = user.person
          if person.nil?
            csv << ["No person record found", "No person record", user.oim_id, user.email,'', user.created_at, user.last_sign_in_at, user.last_portal_visited]
          elsif person.has_active_employer_staff_role?
            employer_profile_id = person.employer_staff_roles.first.employer_profile_id
            employer_profile = EmployerProfile.find(employer_profile_id)
            employer_profile.broker_agency_accounts.unscoped.all.each do |baa|
              #next if baa.nil? || baa.broker_agency_profile.nil? || baa.broker_agency_profile.market_kind == "individual"
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, "employer staff", user.created_at, user.last_sign_in_at, user.last_portal_visited, baa.try(:start_on), baa.try(:end_on)]
            end
          elsif person.employee_roles?
            person.employee_roles.each do |emp|
              ce = emp.census_employee
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, "employee", user.created_at, user.last_sign_in_at, user.last_portal_visited, ce.hired_on, ce.employment_terminated_on]
            end
          elsif person.hbx_staff_role?
            if user.oim_id.match(/.*disable/i).present?
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.person.hbx_staff_role.permission.name, user.created_at, user.last_sign_in_at.strftime("%m/%d/%Y"), user.person.hbx_staff_role.created_at.strftime("%m/%d/%Y"), user.updated_at.strftime("%m/%d/%Y")]
            else
              csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.person.hbx_staff_role.permission.name, user.created_at, user.last_sign_in_at.strftime("%m/%d/%Y"), user.person.hbx_staff_role.created_at.strftime("%m/%d/%Y"), 'Active']
            end
          elsif person.assister_role?
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, "assister", user.created_at, user.last_sign_in_at, user.last_portal_visited ]
          elsif person.csr_role?
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, "csr", user.created_at, user.last_sign_in_at, user.last_portal_visited ]
          elsif person.consumer_role?
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, "consumer", user.created_at, user.last_sign_in_at, user.last_portal_visited ]
          end
        rescue Exception => e
          puts "Errors #{e} #{e.backtrace}"
        end
        processed_count += 1
      end
      offset = offset + batch_size
    end
    puts "#{processed_count} users to output file: #{file_name}" unless Rails.env.test?
  end