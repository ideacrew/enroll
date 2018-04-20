require 'csv'

namespace :reports do

    desc "Special Enrollments"
    task :special_enrollment => :environment do
      
      orgs = Organization.where({:"employer_profile.plan_years" => { 
        :$elemMatch => { 
          :start_on => Date.new(2017,7,1),
          :aasm_state.in => (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE)
        }
      }})

      field_names  = %w(
          HBX_ID
          ENROLLMENT_KIND
          KIND
          PERSON_HBX_ID
          SUBMITTED_AT
          EMPLOYER_LEGAL_NAME
          FEIN
        )

     file_name = "#{Rails.root}/special_enrollment_employees.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      orgs.each do |org|
        begin
          py = org.employer_profile.plan_years.where(start_on:Date.new(2017,07,01), aasm_state: 'active').first
          id_list = py.benefit_groups.collect(&:_id).uniq
          puts "processing #{org.legal_name}"
          families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
          families.inject([]) do |enrollments, family|
            family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list, :aasm_state.in => HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).each do |hbx|
              if (py.open_enrollment_start_on..py.open_enrollment_end_on).cover?(hbx.submitted_at)
                if (hbx.enrollment_kind == "special_enrollment" || hbx.census_employee.new_hire_enrollment_period.cover?(hbx.submitted_at))
                  csv << [
                          hbx.hbx_id, 
                          hbx.enrollment_kind,
                          hbx.kind,
                          hbx.family.primary_applicant.person.hbx_id,
                          hbx.submitted_at,
                          hbx.census_employee.employer_profile.legal_name,
                          hbx.census_employee.employer_profile.fein
                          ] 
                end
              end
            end
          end
        rescue
          puts "Bad Record"
        end
      end
    end
  end
end   
