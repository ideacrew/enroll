#This rake task used to generate people details for DC-Audits.
#To run task: RAILS_ENV=production bundle exec rake reports:people_details person_hbx_ids="183335,19833603,19919759,19939908,19959024,20024511,20024849,20071923,20084786,19911988,20043654,20045432,20080031"
require 'csv'

namespace :reports do

  desc "details of a person and its linked families with their enrollments"
  task :people_details => :environment do

    def find_person_detail(person_hbx_ids)
      headers = ['Given HBXID','Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage End','Market kind', 'Coverage Kind', 'Enrollment State', 'Mem Hbx_id', 'Primary Relationship', 'First Name','Last Name', 'Family Size']
      file_name = "#{Rails.root}/people_details_report.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << headers
        given_ids = person_hbx_ids.to_s.split(',').uniq
        given_ids.each do |given_id|
          person_record = Person.by_hbx_id(given_id)
          if person_record.count > 0
            household = person_record.first.families.first.active_household
            if household.present?
              enrollment_ids_final = household.hbx_enrollments.map(&:hbx_id)
              if enrollment_ids_final.present?
                enrollment_ids_final.each do |id|
                  hbx_enrollment = HbxEnrollment.by_hbx_id(id).first
                  next if hbx_enrollment.aasm_state == "shopping"

                  hbx_members = hbx_enrollment.hbx_enrollment_members
                  if hbx_members.count > 0
                    hbx_members.each do |mem|
                      primary_relationship = mem.try(:primary_relationship)
                      mem_hbx_id = mem.try(:hbx_id)
                      first_name = mem.try(:person).try(:first_name)
                      last_name = mem.try(:person).try(:last_name)

                      csv << [given_id,hbx_enrollment.hbx_id,hbx_enrollment.created_at,hbx_enrollment.effective_on,hbx_enrollment.terminated_on,hbx_enrollment.try(:kind), hbx_enrollment.try(:coverage_kind),hbx_enrollment.try(:aasm_state),mem_hbx_id,primary_relationship,first_name,last_name,hbx_enrollment.hbx_enrollment_members.try(:size)]
                    end
                  else
                    puts "given hbx_id:#{given_id} and its related Enrollment with enr_hbx_id: #{hbx_enrollment.hbx_id} and enrollment state: #{hbx_enrollment.aasm_state} does not have hbx_enrollment_members to it"
                  end
                end
              else
                puts "given hbx_id:#{given_id} and its related family does not have enrollments to it"
              end
            else
              puts "given Hbx_id:#{given_id} does not have linked active_household for the family"
            end
          else
            puts "given Hbx_id:#{given_id} does not have person record to it"
          end
        end
      end
    end

    find_person_detail(ENV["person_hbx_ids"])
  end
end
