require 'csv'

namespace :reports do

    desc "Special Enrollments"
    task :special_enrollment => :environment do
      
      orgs = Organization.where({:"employer_profile.plan_years" => { 
        :$elemMatch => { 
          :start_on => TimeKeeper.date_of_record.prev_month.beginning_of_month
        }
          }})

      field_names  = %w(
          HBX_ID
          ENROLLMENT_KIND
          KIND
          SPECIAL_ENROLLMENT_PERIOD_ID
          SUBMITTED_AT
        )

     file_name = "#{Rails.root}/special_enrollment_employees.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      orgs.each do |org|
        org.employer_profile.plan_years.where(start_on:Date.new(2017,07,01)).first.hbx_enrollments do |hbx| 
          py = org.employer_profile.plan_years.where(start_on:Date.new(2017,07,01)).first
          if hbx.enrollment_kind == "special_enrollment" && HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.include?(hbx.aasm_state) && (py.open_enrollment_start_on..py.open_enrollment_end_on).cover?(hbx.submitted_at) 
            csv << [
            hbx.hbx_id, 
            hbx.enrollment_kind,
            hbx.kind,
            hbx.special_enrollment_period_id,
            hbx.submitted_at
            ] 
          end
        end
      end
    end
  end
end    