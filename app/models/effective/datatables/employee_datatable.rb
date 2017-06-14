module Effective
  module Datatables
    class EmployeeDatatable < Effective::MongoidDatatable

      datatable do

        # TODO: Implement Filters here
        bulk_actions_column do
          bulk_action 'Employee will enroll',  change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"enroll"), data: {confirm: 'Are you sure? Do you want to make enroll?', no_turbolink: true}
          bulk_action 'Employee will not enroll with valid waiver', change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"waive"), data: {confirm: 'Are you sure? Do you want to make Waive?', no_turbolink: true}
          bulk_action 'Employee will not enroll with invalid waiver', change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection=>"will_not_participate"), data: {confirm: 'Are you sure? Do you want to make will not participate?', no_turbolink: true}
        end

        table_column :EmployeeName, :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.full_name, employers_employer_profile_census_employee_path(@employer_profile.id, row.id)) + raw("<br>")
        }, :sortable => false, :filter => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
          row.dob
        }, :sortable => false, :filter => false

        table_column :Hired, :proc => Proc.new { |row|
          row.hired_on
        }, :sortable => false, :filter => false

        table_column :status, :proc => Proc.new { |row|
          employee_state_format(row.aasm_state, row.employment_terminated_on)
        }, :sortable => false, :filter => false

        table_column :BenefitPackage, :proc => Proc.new { |row|
          row.active_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
        }, :sortable => false, :filter => false

        if attributes["renewal"]
          table_column :renewalbenefitpackage, :label => 'Renewal Benefit Package', :proc => Proc.new { |row|
            row.renewal_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        if attributes["terminated"]
          table_column :TerminationDate, :proc => Proc.new { |row|
            row.employment_terminated_on
          }, :filter => false, :sortable => false
        end

        table_column :EnrollmentStatus, :proc => Proc.new { |row|
            enrollment_state(row)
        }, :sortable => false, :filter => false

        table_column :Est_Participation, :proc => Proc.new { |row|
           row.expected_selection.titleize if row.expected_selection
        }, :sortable => false, :filter => false

        if attributes["renewal_status"]
          table_column :RenewalEnrollmentStatus, :proc => Proc.new { |row|
            renewal_enrollment_state(row)
          }, :filter => false, :sortable => false
        end

        table_column :Action, :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          # Has to specify the valid route path for rehire and initiate cobra
          dropdown = [
              # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
              ['Edit', edit_employers_employer_profile_census_employee_path(@employer_profile, row.id), 'static'],
              ['Terminate', show_employee_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: "census_employeeid_#{row.id.to_s}", census_employee: row.id), 'ajax'],
              ['Rehire', rehire_employee_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: "census_employeeid_#{row.id.to_s}", census_employee: row.id), 'ajax'],
              ['Initiate Cobra', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), 'static']
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "census_employeeid_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        return @employee_collection if defined? @employee_collection
        employer_profile = EmployerProfile.find(attributes["id"])
        @employer_profile = employer_profile
        @employee_collection = employer_profile.census_employees.active
      end

      def nested_filter_definition
        # name = collection
        filters = {
            employers:
                [
                    {scope: 'eligible', label: 'Active & COBRA'},
                    {scope: 'active', label: 'Active only'},
                    {scope: 'by_cobra', label: 'COBRA only'},
                    {scope: 'terminated', label: 'Terminated'},
                    {scope: 'eligible', label: 'All'}
                ],
            top_scope: :employers
        }
      end
    end
  end
end
