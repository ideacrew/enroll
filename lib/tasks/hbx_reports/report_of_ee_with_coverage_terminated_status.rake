require 'csv'

namespace :reports do
  namespace :shop do
    desc "Employee with coverage termianted enrollment status on employer roaster"
    task :ee_with_coverage_terminated_enrollment_status => :environment do
      file_name = "#{Rails.root}/ee_with_coverage_terminated_enrollment_status.csv"
      @count = 0
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        field_names= %w(
                 employee_name
                 employee_hix_id
                 er_legal_name
                 plan_name
                 policy_id
                 coverge_start_date
                 coverage_termination_date
                    )
        csv << field_names
        Organization.exists(:employer_profile => true ).each do |organization|
          organization.employer_profile.census_employees.each do |ce|
            if ce.active_benefit_group_assignment.present?
              enrollments = ce.active_benefit_group_assignment.hbx_enrollments

              #for health case
              enrollment = enrollments.detect{|enrollment| enrollment.coverage_kind == 'health' && enrollment.aasm_state == "coverage_terminated"}
              unless enrollment.nil? || ce.employee_role.nil? || ce.employee_role.person.nil?
                csv <<[  ce.employee_role.person.full_name,
                         ce.employee_role.person.hbx_id,
                         enrollment.employer_profile.legal_name,
                         enrollment.plan.nil? ? "" : enrollment.plan.name,
                         enrollment.hbx_id,
                         enrollment.effective_on,
                         enrollment.terminated_on
                ]
                @count = @count+1
              end
              # for dental case
              enrollment = enrollments.detect{|enrollment| enrollment.coverage_kind == 'dental' && enrollment.aasm_state == "coverage_terminated"}
              unless enrollment.nil? || ce.employee_role.nil? || ce.employee_role.person.nil?
                csv <<[  ce.employee_role.person.full_name,
                         ce.employee_role.person.hbx_id,
                         enrollment.employer_profile.legal_name,
                         enrollment.plan.nil? ? "" : enrollment.plan.name,
                         enrollment.hbx_id,
                         enrollment.effective_on,
                         enrollment.terminated_on
                ]
                @count = @count+1
              end
              if @count%100 == 0
                puts @count
              end
            end
          end
        end
      end
    end
  end
end

