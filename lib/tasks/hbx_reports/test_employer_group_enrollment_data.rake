require 'roo'
# To run: 
# RAILS_ENV=production bundle exec rake reports:shop:test_employer_group_enrollment_data filename='sample.xlsx'

namespace :reports do
  namespace :shop do
  

  desc "Enrollment data for test employers"
    task :test_employer_group_enrollment_data => :environment do 
      original_spreadsheet = Roo::Spreadsheet.open(ENV['filename'])
      hash_headers = {}
    
      # Pull the header row.
      headers = original_spreadsheet.row(1)

      # create a hash to use for the header row
      headers.each do |header|
        hash_headers[header.downcase.strip.gsub(" ","_")] = header
      end

      employer_count = 0
      employee_count = 0
      employees_with_no_enrollments_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      filename = "hbx_report/#{ENV['filename']}_results_#{Time.now.strftime('%Y%m%d%H%M')}.csv"
      CSV.open(filename,"w") do |csv|
        csv << ["Group", "FEIN", "Name","Person HBX ID","Enrollment HBX ID", "Subscriber/Dependent","Enrollment Status","Broker Name","Broker NPN","Broker FEIN"]
        original_spreadsheet.each(hash_headers) do |hash|
          employer_count += 1
          next if employer_count == 1
          puts "#{employer_count} employers analyzed." if employer_count % 10 == 0
          fein = format_fein(hash["fein"].to_i.to_s)
          employer_profile = EmployerProfile.find_by_fein(fein)
          next if employer_profile.blank?
          enrollment_statuses = HbxEnrollment::ENROLLED_STATUSES+HbxEnrollment::RENEWAL_STATUSES+HbxEnrollment::TERMINATED_STATUSES+HbxEnrollment::CANCELED_STATUSES
          employee_count += employer_profile.census_employees.size
          employer_profile.census_employees.each do |ce|
            enrollments = find_enrollments(ce,enrollment_statuses)
            if enrollments.blank?
              employees_with_no_enrollments_count += 1
              next
            end
            enrollments.each do |en|
              next if en.aasm_state == "shopping"
              next unless en.is_shop?
              next unless en.employer_profile == employer_profile
              group_name = en.employer_profile.legal_name
              group_fein = en.employer_profile.fein
              enrollment_hbx_id = en.hbx_id
              enrollment_state = en.aasm_state
              if en.broker_agency_account.present? && en.broker_agency_account.writing_agent.present?
                broker_name = en.broker_agency_account.writing_agent.person.full_name
                broker_npn = en.broker_agency_account.writing_agent.npn
                broker_fein = en.broker_agency_account.broker_agency_profile.fein
              end
              en.hbx_enrollment_members.each do |hbx_em|
                name = hbx_em.person.full_name
                hbx_id = hbx_em.person.hbx_id
                if hbx_em.is_subscriber?
                  subdep = "Subscriber"
                else
                  subdep = "Dependent"
                end
                csv << [group_name,group_fein,name,hbx_id,enrollment_hbx_id,subdep,enrollment_state,broker_name,broker_npn,broker_fein]
              end
            end
          end
        end
      end
      puts "#{employees_with_no_enrollments_count} employees do not have enrollments out of a total of #{employee_count} employees." unless Rails.env.test?
    end
  end
end

def format_fein(fein)
  return nil if fein.blank?
  fein.gsub!(/-/,'')
  (9 - fein.size).times{ fein = prepend_zero(fein) }
  fein
end

def prepend_zero(string)
  '0' + string
end

def find_enrollments(census_employee,valid_statuses)
  return nil if census_employee.employee_role.blank?
  return nil if census_employee.employee_role.person.blank?
  return nil if census_employee.employee_role.person.primary_family.blank?
  return nil if census_employee.employee_role.person.primary_family.active_household.blank?
  return nil if census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.blank?
  enrollments = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.select{|hbx_en| valid_statuses.include?(hbx_en.aasm_state)}
  return enrollments
end