require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employer plan year application status by effective date"
    task :employer_roster_report => :environment do

      organizations = Organization.exists(:employer_profile => true).where(:"hbx_id".nin => [100101, 100102, 118510]).limit(100)
    
      CSV.open("#{Rails.root}/public/er_roster_report.csv", "w", force_quotes: true) do |csv|
        csv << ["EE first name","EE last name","ER legal name","ER DBA name","ER FEIN","SSN","Date of Birth","Date of Hire","Date added to roster","Employment status","Date of Termination","Email","Address","Roster Status","EE's HIX ID"]
        organizations.each do |organization|
          employer_profile = organization.employer_profile
          next if employer_profile.census_employees.blank?
          employer_data = [organization.legal_name, organization.dba, organization.fein]

          employer_profile.census_employees.active.each do |active_employee|
            data = build_employee_row(active_employee, employer_data)
            csv << data
          end

          employer_profile.census_employees.terminated.each do |active_employee|
            data = build_employee_row(active_employee, employer_data)
            csv << data
          end
        end
      end
    end
  end
end


def build_employee_row(employee, employer_data)
  data = [
    employee.first_name,
    employee.last_name
  ]
  data += employer_data
  data += [
    employee.ssn,
    format_date(employee.dob),
    format_date(employee.hired_on),
    format_date(employee.created_at),
    employment_status(employee.aasm_state),
    employment_status(employee.aasm_state) == 'terminated' ? format_date(employee.employment_terminated_on) : "",
    employee.email_address,
    employee.try(:address).try(:full_address) || '',
    employee.aasm_state.humanize,
    employee.employee_role.try(:hbx_id)
  ]
  data 
end

def employment_status(aasm_state)
  case aasm_state.to_s
  when 'employment_terminated'
    'terminated'
  when 'rehired'
    'rehired'
  else
    'active'
  end
end

def format_date(date)
  return '' if date.blank?
  date.strftime("%m/%d/%Y")
end