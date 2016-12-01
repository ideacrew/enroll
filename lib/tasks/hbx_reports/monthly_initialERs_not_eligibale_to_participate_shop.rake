# Monthly implementation list of initial ERs that do not meet eligibility to participate in SHOP
# Business Rules
# 1. They have no enrollees
# 2. The only enrollee is listed as the owner of the company
# 3. The primary address is not a Washington DC address
# 4. The percentage of employees that submit an enrollment or waive is less that 2/3 (67%)

require 'csv'
namespace :reports do
  namespace :shop do
    desc "List of initial_ERs not_meet eligibility to participate in shop"
    task :initial_ERs_not_qualified_to_shop => :environment do
      count = 0
      #need to add a date as input
      renewal_policy_date = Date.new(2016,9,1)
      initial_employers = Organization.where(:"start_on" => Date.new(2016,2,1),:"employer_profile.plan_years" => {:$elemMatch => { :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE+ ['draft']}})
      field_names  = %w(
                        Employer_Name
                        Employer_Fein
                        Employee_HBX_ID
                        Number_of_Enrolled_Employee
                        Participation_Rate
                        Is_owner_the_only_enrollee?(Y/N)
                        Non-DC primary address? (Y/N)
                        )

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/List_of_initial_ERs_not_meet_eligibility_to_participate_in_shop.csv"
      CSV.open(file_name, "w") do |csv|
        csv << field_names
        initial_employers.each do |employer|

          census_employees = employer.employer_profile.census_employees

          # 1. They have no enrollees
          # 2. The only enrollee is listed as the owner of the company
          # 3. The primary address is not a Washington DC address
          # 4. The percentage of employees that submit an enrollment or waive is less that 2/3 (67%)
          condition_1= census_employees.size==0
          condition_2= (census_employees.size==1 && census_employees.first.is_business_owner)
          condition_3=!employer.employer_profile.is_primary_office_local?
          #plan_year=employer.employer_profile.active_plan_year
          condition_4= (plan_year.eligible_to_enroll_count/plan_year.total_enrolled_count<2/3)
          if condition_1 || condition_2 || condition_3 || condition_4
              csv << [
                    employer.legal_name,
                    employer.fein,
                    employer.hbx_id,
                    employer.employer_profile.census_employees,
                    # Participation_Rate
                    employer.employer_profile.census_employees.size==1
                    employer.employer_profile.is_primary_office_local?
                ]
              count += 1
          end
        end
        puts "Waiver Report for Employees Generated on #{Date.today}, Total initial Employers count #{count} and Employer information output file: #{file_name}"
      end # CSV close
    end

  end
end