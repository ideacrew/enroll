# Daily Report: Rake task to find terminated hbx_enrollment
# To Run Rake Task without custom dates: RAILS_ENV=production rake reports:enrollment_termination_on
# To Run Rake Task with custom dates: RAILS_ENV=production rake reports:enrollment_termination_on[Y-m-d, Y-m-d]
# example for running Rake Task with custom dates: bundle exec rake reports:enrollment_termination_on[2016-6-29,2016-8-30]
require 'csv'

namespace :reports do
  desc "List of people with terminated hbx_enrollment"
  task :enrollment_termination_on, [:start_date, :end_date] => :environment do |t, args|
    if args[:start_date] && args[:end_date]
      date_of_termination=Date.strptime(args[:start_date], '%Y-%m-%d').beginning_of_day..Date.strptime(args[:end_date], '%Y-%m-%d').end_of_day
    else
      date_of_termination=Date.yesterday.beginning_of_day..Date.yesterday.end_of_day
    end
    #find families who terminated their hbx_enrollments
    families = Family.where(:"households.hbx_enrollments" =>
                                {:$elemMatch =>
                                     {'$or'=>
                                          [{:"aasm_state" => "coverage_terminated"},
                                           {:"aasm_state" => "coverage_termination_pending"}],
                                      :"termination_submitted_on" => date_of_termination}})
    field_names  = %w(
               Enrolled_Member_HBX_ID
               Enrolled_Member_First_Name
               Enrolled_Member_Last_Name
               Employer_Legal_Name
               Employer_Fein
               Employee_Census_State
               Primary_Member_HBX_ID
               Primary_Member_First_Name
               Primary_Member_Last_Name
               Market_Kind
               Carrier_Legal_Name
               Plan_Name
               Coverage_Type
               HIOS_ID
               Policy_ID
               Enrollment State
               Effective_Start_Date
               Coverage_End_Date
               Member_relationship
               Coverage_state_occured)

    processed_count = 0
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/edi_enrollment_termination_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      families.each do |family|
        if family.try(:primary_family_member).try(:person).try(:active_employee_roles).try(:any?) || family.try(:primary_family_member).try(:person).try(:consumer_role)
          hbx_enrollments = family.active_household.hbx_enrollments.select{|hbx| (hbx.coverage_terminated? || hbx.coverage_termination_pending?) && hbx.termination_submitted_on.try(:strftime, '%Y-%m-%d') == Date.yesterday.strftime('%Y-%m-%d')}
          hbx_enrollment_members = hbx_enrollments.flat_map(&:hbx_enrollment_members)
          hbx_enrollment_members.each do |hbx_enrollment_member|
            if hbx_enrollment_member
              person = hbx_enrollment_member.person
              enrollment = hbx_enrollment_member.hbx_enrollment
              primary_person = family.primary_family_member.person
              employer = enrollment.try(:employer_profile)
              census_employee = person.try(:employee_roles).try(:first).try(:census_employee)
              csv << [
                  person.hbx_id,
                  person.first_name,
                  person.last_name,
                  employer ? employer.legal_name : "IVL",
                  employer ? employer.fein : "IVL",
                  census_employee ? census_employee.aasm_state : "IVL",
                  primary_person.hbx_id,
                  primary_person.first_name,
                  primary_person.last_name,
                  enrollment.kind,
                  enrollment.plan.carrier_profile.legal_name,
                  enrollment.plan.name,
                  enrollment.coverage_kind,
                  enrollment.plan.hios_id,
                  enrollment.hbx_id,
                  enrollment.aasm_state,
                  enrollment.effective_on,
                  enrollment.terminated_on,
                  primary_person.find_relationship_with(person),
                  enrollment.termination_submitted_on
              ]
            end
            processed_count += 1
          end
        end
      end
      puts "For date #{date_of_termination}, total terminated hbx_enrollments count #{processed_count} and output file is: #{file_name}"
    end
  end
end
