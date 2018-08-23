namespace :conversion_import do
  desc "Import given fein employers into CSV sheet"
  task employers: :environment do |_, args|
    file_name = File.expand_path("#{Rails.root}/public/employers_export_conversion.csv")
    csv_headers = %w(action FEIN Doing_Business_As Legal_Name Issuer_Assigned_Employer_Id Sic_Code Physical_Address_1 Physical_Address_2 City County County_FIPS_Code State Zip Mailing_Address_1 Mailing_Address_2 City State Zip Contact_First_Name Contact_Last_Name Contact_Email Contact_Phone
                     Contact_Phone_Extension Enrolled_Employee_count New_Hire_Coverage_Policy Contact_Address_1 Contact_Address_2 City State Zip Broker_Name Broker_NPN TPA_Name TPA_Fein Coverage_Start_Date)

    feins = ENV['feins_list'].split(' ')
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << csv_headers
      feins.each do |fein|
        organization = find_organization(fein.to_s)
        next unless organization

        physical_location, mailing_location = find_address_details(organization)

        #In conversion sheet we have only one staff role
        available_staff_roles = find_staff_role(organization).first
        physical_address = physical_location.address
        mailing_attributes = mailing_address_attributes(mailing_location.address)
        staff_role_attributes = append_attributes(available_staff_roles)
        benefit_application = find_plan_year(organization).first
        probation_kind = benefit_application.benefit_packages.first.probation_period_kind.to_s
        applications  = [benefit_application.fte_count, probation_kind, benefit_application.effective_period.min]

        empty_arr = Array.new
        attributes_not_used = 8.times do
          empty_arr.push ""
        end

        csv << ["Add",
                organization.fein,
                organization.dba,
                organization.legal_name,
                "",
                organization.employer_profile.sic_code,
                physical_address.address_1,
                physical_address.address_2,
                physical_address.city,
                physical_address.county,
                "",
                physical_address.state,
                physical_address.zip
        ] + mailing_attributes + staff_role_attributes + attributes_not_used + applications
      end
      puts "Successfully Generated CSV placed in #{file_name}" unless Rails.env.test?
    end
  end

  desc "Import Employee details into CSV"
  task employees: :environment do |_, args|
    file_name = File.expand_path("#{Rails.root}/public/employees_export_conversion.csv")
    headers = %w(sponsor_name fein hired_on benefit_begin_date premium_total employer_contribution subscriber_ssn subscriber_dob subscriber_gender subscriber_first_name subscriber_middle_initial subscriber_last_name subscriber_email subscriber_phone
                     subscriber_address_1 subscriber_address_2 subscriber_city subscriber_state subscriber_zip)
    dep_headers = []
    7.times do |i|
      ["SSN", "DOB", "Gender", "First Name", "Middle Name", "Last Name", "Email", "Phone", "Address 1", "Address 2", "City", "State", "Zip", "Relationship"].each do |h|
        dep_headers << "Dep#{i + 1} #{h}"
      end
    end
    feins_list = ENV['feins_list'].split(' ')

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << headers + dep_headers

      feins_list.each do |fein|
        organization = find_organization(fein)
        census_employees = find_census_employees(organization)
        benefit_application = find_plan_year(organization).renewing.first
        coverage_start = benefit_application.effective_period.min
        census_employees.each do |census_employee|
          premium_total, employer_contribution = find_contribution_details(census_employee)
          census_employee_details = find_initial_attributes(census_employee)
          address_details  = address_attributes(census_employee)
          unless census_employee.census_dependents.empty?
            dependents = Array.new
            census_employee.census_dependents.each do |dependent|
              initial_details = find_initial_attributes(dependent)
              address_details = address_attributes(dependents)
              dependents << initial_details
              dependents << ""
              dependents << address_details
              dependents << dependent.employee_relationship
            end
          end
          csv << [organization.legla_name, fein, census_employee.hired_on, coverage_start,  premium_total, employer_contribution] + census_employee_details + "" + address_details + "" + dependents
        end
      end
    end


  end

  def find_contribution_details(census_employee)
   hbx_enrollment = census_employee.published_benefit_group_assignment.hbx_enrollments.active
   [hbx_enrollment.total_premium, hbx_enrollment.total_employer_contribution]
  end

  def find_initial_attributes(census_employee)
    initial_attr = Array.new
    %w(ssn dob gender first_name middle_name last_name).each do |attr|
      initial_attr << census_employee.send(attr)
    end
    initial_attr
  end

  def address_attributes(census_employee)
    address = Array.new
    %w(address_1 address_2 city state zip).each do |attr|
      address << census_employee.address.send(attr)
    end
    address
  end

  def find_census_employees(organization)
    sponsorship = organization.active_benefit_sponsorship
    employer_profile = organization.employer_profile
    CensusEmployee.where(benefit_sponsors_employer_profile_id: employer_profile.id, benefit_sponsorship_id: sponsorship.id)
  end

  def find_plan_year(organization)
    organization.benefit_sponsorships.first.benefit_applications
  end

  def append_attributes(person)
    staff_details = Array.new
    staff_details << person.first_name
    staff_details << person.last_name
    staff_details << person.emails.first.address
    staff_details << person.phones.first.full_phone_number
    staff_details << ""

    staff_details
  end

  def mailing_address_attributes(mailing_location)
    if mailing_location
      location_details = Array.new
      location_details << mailing_location.address_1
      location_details << mailing_location.address_2
      location_details << mailing_location.city
      location_details << mailing_location.state
      location_details << mailing_location.zip
    else
      location_details = ["", "", "", "", ""]
    end
    location_details
  end

  def find_address_details(organization)
    office_locations = organization.employer_profile.office_locations
    # In conversion we will have only one primary and mailing office locations in the sheet
    primary_office_location = office_locations.where(is_primary: true).first
    mailing_office_location = office_locations.where(is_primary: false).first
    [primary_office_location, mailing_office_location]
  end

  def find_staff_role(organization)
    organization.employer_profile.staff_roles
  end

  def find_organization(fein)
    BenefitSponsors::Organizations::Organization.where(fein: fein).first
  end
end


