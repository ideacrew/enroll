namespace :conversion_import do
  desc "Import given fein employers into CSV sheet"
  task employers: :environment do |_, args|
    file_name = File.expand_path("#{Rails.root}/public/employers_export_conversion.csv")
    csv_headers = %w(Action FEIN Doing\ Business\ As Legal\ Name Issuer\ Assigned\ Employer\ ID SIC\ code Physical\ Address\ 1 Physical\ Address\ 2 City County County\ FIPS\ code State Zip Mailing\ Address\ 1 Mailing\ Address\ 2
                     City State Zip Contact\ First\ Name Contact\ Last\ Name Contact\ Email Contact\ Phone Contact\ Phone\ Extension Enrolled\ Employee\ Count New\ Hire\ Coverage\ Policy Contact\ Address\ 1 Contact\ Address\ 2
                     City State Zip Broker\ Name Broker\ NPN TPA\ Name TPA\ Fein Coverage\ Start\ Date Carrier\ Selected Plan\ Selection\ Category Plan\ Name Plan\ HIOS\ ID Employer\ Contribution\ -\ Employee Employer\ Contribution\ -\ Spouse
                     Employer\ Contribution\ -\ Domestic\ Partner Employer\ Contribution\ -\ Child\ under\ 26)
    feins = ENV['feins_list'].split(' ')
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << csv_headers
      feins.each do |fein|
        organization = find_organization(fein.to_s)
        next unless organization

        physical_location, mailing_location = find_address_details(organization)

        #In conversion sheet we have only one staff role
        available_staff_roles = find_staff_roles(organization).first
        physical_address = physical_location.address

        if mailing_location
          mailing_attributes = mailing_address_attributes(mailing_location.address)
        else
          mailing_attributes = mailing_address_attributes(nil)
        end

        # mailing_attributes = mailing_address_attributes(mailing_location.address)
        staff_role_attributes = append_attributes(available_staff_roles)
        benefit_applications = find_plan_year(organization)
        benefit_application = benefit_applications.renewing.present? ?  benefit_applications.renewing.first : benefit_applications.active.first

        probation_kind = benefit_application.benefit_packages.first.probation_period_kind.to_s
        start_on = [benefit_application.effective_period.min]

        empty_arr = Array.new
        9.times do
          empty_arr.push ""
        end

        applications  = [benefit_application.fte_count, probation_kind]
        csv << ["Update",
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
        ] + mailing_attributes + staff_role_attributes + applications + empty_arr + start_on
      end
      puts "Successfully Generated CSV placed in #{file_name}" unless Rails.env.test?
    end
  end

  desc "Import Employee details into CSV"
  task employees: :environment do |_, args|
    file_name = File.expand_path("#{Rails.root}/public/employees_export_conversion.csv")
    headers = %w(Action Type\ Of\ Enrollment Market Sponsor\ Name FEIN Issuer\ Assigned\ Employer\ ID  HIRED\ ON Benefit\ Begin\ Date Plan\ Name HIOS\ ID Premium\ Total Employer\ Contribution Employee\ Responsible\ Amount  Subscriber\ SSN Subscriber\ DOB Subscriber\ Gender Subscriber\ First\ Name Subscriber\ Middle\ Name Subscriber\ Last\ Name Subscriber\ Email Subscriber\ Phone
                     Subscriber\ Address\ 1 Subscriber\ Address\ 2 Subscriber\ City Subscriber\ State Subscriber\ Zip SELF)
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
        benefit_applications = find_plan_year(organization)
        benefit_application = benefit_applications.renewing.present? ? benefit_applications.renewing.first : benefit_applications.active.first
        coverage_start = benefit_application.effective_period.min
        census_employees.active.each do |census_employee|
          premium_total, employer_contribution = find_contribution_details(census_employee)
          census_employee_details = find_initial_attributes(census_employee)
          address_details  = address_attributes(census_employee)
          email_address = census_employee.email.present? ? census_employee.email.address : nil
          personal_details = [email_address, ""]
          dependents = Array.new
          unless census_employee.census_dependents.empty?
            dependents = fetch_dependents_details(census_employee)
          end
          csv << ["Add", "New Enrollment", "SHOP", organization.legal_name, fein, "", census_employee.hired_on, coverage_start, "", "", premium_total, employer_contribution, ""] + census_employee_details + personal_details + address_details + dependents
        end
      end
    end
  end

  def fetch_dependents_details(census_employee)
    dependents = Array.new
    census_employee.census_dependents.each do |dependent|
      %w(ssn dob gender first_name middle_name last_name).each do |attr|
        dependents.push dependent.send(attr)
      end
      # for dependents email, phone columns
      dependents.push("","")

      %w(address_1 address_2 city state zip).each do |attr|
        if dependent.address
          dependents.push dependent.send(attr)
        else
          dependents.push("", "", "", "")
        end
      end
    end
    dependents
  end

  def find_contribution_details(census_employee)
    benefit_group_assignment = census_employee.published_benefit_group_assignment
    hbx_enrollment = benefit_group_assignment.active_enrollments.first if benefit_group_assignment
    if hbx_enrollment
      [hbx_enrollment.total_premium.to_f, hbx_enrollment.total_employer_contribution.to_f]
    else
      ["", ""]
    end
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
    # for SELF column
    address.push ""
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

  def find_staff_roles(organization)
    organization.employer_profile.staff_roles.select{|person| person.emails.present? && person.phones.present?}
  end

  def find_organization(fein)
    BenefitSponsors::Organizations::Organization.where(fein: fein).first
  end
end


