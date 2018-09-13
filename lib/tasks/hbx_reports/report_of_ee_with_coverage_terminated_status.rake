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
                 employer_hbx_id
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
              families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_assignment_id => ce.active_benefit_group_assignment.id, :aasm_state => 'coverage_terminated'}})
              next if families.empty?
              families.each do |family|
                enrollment=family.active_household.hbx_enrollments.where({:benefit_group_assignment_id => ce.active_benefit_group_assignment.id, :aasm_state => 'coverage_terminated'}).first
                unless enrollment.nil?
                  csv <<[  family.primary_applicant.person.full_name,
                           family.primary_applicant.person.hbx_id,
                           enrollment.employer_profile.legal_name,
                           enrollment.plan.nil? ? "" : enrollment.plan.name,
                           enrollment.hbx_id,
                           enrollment.effective_on,
                           enrollment.terminated_on
                  ]
                  @count = @count+1
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
  end
end
