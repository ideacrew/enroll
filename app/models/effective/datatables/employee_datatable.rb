module Effective
  module Datatables
    class EmployeeDatatable < Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do
        
       # TODO: This sis the original code
       #  unless aca_state_abbreviation == "DC"
       # Make sure that it is cofigured for non DC versions!
       if EnrollRegistry.feature_enabled?(:employee_datable_waiver_bulk_actions)
          bulk_actions_column do
            bulk_action 'Employee will enroll',
                        main_app.change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection => "enroll"),
                        data: {confirm: 'These employees will be used to estimate your group size and participation rate', no_turbolink: true}
            bulk_action 'Employee will not enroll with valid waiver',
                        main_app.change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection => "waive"),
                        data: {confirm: 'Remember, your group size can affect your premium rates', no_turbolink: true}
            bulk_action 'Employee will not enroll with invalid waiver',
                        main_app.change_expected_selection_employers_employer_profile_census_employees_path(@employer_profile,:expected_selection => "will_not_participate"),
                        data: {confirm: 'Remember, your participation rate can affect your group premium rates', no_turbolink: true}
          end
        end

        table_column :employee_name, :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.full_name, main_app.employers_employer_profile_census_employee_path(@employer_profile.id, row.id, tab: 'employees')) + raw("<br>")
        }, :sortable => false, :filter => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
          row.dob.strftime("%m/%d/%Y") if row.dob.present?
        }, :sortable => false, :filter => false

        table_column :hired_on, :proc => Proc.new { |row|
          row.hired_on.strftime("%m/%d/%Y") if row.hired_on.present?
        }, :sortable => false, :filter => false

        table_column :terminated_on, :proc => Proc.new { |row|
          row.employment_terminated_on.present? ? row.employment_terminated_on.strftime("%m/%d/%Y") : "Active"
        }, :sortable => false, :filter => false, :visible => true

        table_column :status, :proc => Proc.new { |row|
          employee_state_format(row, row.aasm_state, row.employment_terminated_on)
        }, :sortable => false, :filter => false

        unless attributes['current_py_terminated']
          if attributes['reinstated']
            table_column :benefit_package, :label => 'Reinstated Benefit Package', :proc => proc { |row|
              row.active_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
            }, :sortable => false, :filter => false
          else
            table_column :benefit_package, :proc => proc { |row|
              row.active_benefit_group_assignment.benefit_group.title.capitalize if row.active_benefit_group_assignment.present?
            }, :sortable => false, :filter => false
          end
        end

        if attributes["future_reinstated"]
          table_column :reinstated_benefit_package, :label => 'Reinstated Benefit Package', :proc => proc { |row|
            row.future_active_reinstated_benefit_group_assignment.benefit_group.title.capitalize if row.future_active_reinstated_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        if attributes["renewal"]
          table_column :renewal_benefit_package, :label => 'Renewal Benefit Package', :proc => Proc.new { |row|
            row.renewal_benefit_group_assignment.benefit_package.title.capitalize if row.renewal_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        if attributes["off_cycle"]
          table_column :off_cycle_benefit_package, :label => 'Off-Cycle Benefit Package', :proc => proc { |row|
            row.off_cycle_benefit_group_assignment.benefit_package.title.capitalize if row.off_cycle_benefit_group_assignment.present?
          }, :filter => false, :sortable => false
        end

        unless attributes['current_py_terminated']
          table_column :enrollment_status, :proc => proc { |row|
            enrollment_state(row)
          }, :sortable => false, :filter => false
        end

        if attributes["future_reinstated"]
          table_column :reinstated_enrollment_status, :proc => proc { |row|
            reinstated_enrollment_state(row)
          }, :sortable => false, :filter => false
        end

        # Do not show column unless renewal_benefit_application aasm state is in PUBLISHED_STATES
        if attributes["renewal"] && attributes["is_submitted"]
          table_column :renewal_enrollment_status, :proc => Proc.new { |row|
            renewal_enrollment_state(row)
          }, :filter => false, :sortable => false
        end

        if attributes["off_cycle"] && attributes["is_off_cycle_submitted"]
          table_column :off_cycle_enrollment_status, :proc => proc { |row|
            off_cycle_enrollment_state(row)
          }, :filter => false, :sortable => false
        end

        unless individual_market_is_enabled?
          table_column :est_participation, :proc => Proc.new { |row|
             row.expected_selection.titleize if row.expected_selection
          }, :sortable => false, :filter => false
        end

        table_column :actions, label: "", :width => '50px', :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          # Has to specify the valid route path for rehire and initiate cobra
          dropdown = [
              # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
              ['Edit', main_app.edit_employers_employer_profile_census_employee_path(@employer_profile, row.id, tab: 'employees'), 'static'],
              ['Terminate', main_app.confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, census_employee: row.id, type: 'terminate', tab: 'employees'), terminate_possible?(row)],
              ['Rehire', main_app.confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, census_employee: row.id, type: 'rehire', tab: 'employees'), rehire_possible?(row)],
              ['Initiate cobra', main_app.confirm_effective_date_employers_employer_profile_census_employees_path(@employer_profile, census_employee_id: row.id, type: 'cobra'), cobra_possible?(row)]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "census_employeeid_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless  (defined? @employees) && @employees.present?   #memoize the wrapper class to persist @search_string
          @employees = Queries::EmployeeDatatableQuery.new(attributes)
        end
        @employees
      end

      def cobra_possible? census_employee
        census_employee.is_cobra_possible? ? 'ajax' : 'disabled'
      end

      def rehire_possible? census_employee
        census_employee.is_rehired_possible? ? 'ajax' : 'disabled'
      end

      def terminate_possible? census_employee
        census_employee.is_terminate_possible? ? 'disabled' : 'ajax'
      end

      def nested_filter_definition
          {
            employers:
                [
                    {scope: 'active_alone', label: 'Active only'},
                    {scope: 'active', label: 'Active & COBRA'},
                    {scope: 'by_cobra', label: 'COBRA only'},
                    {scope: 'terminated', label: 'Terminated'},
                    {scope: 'all', label: 'All'}
                ],
            top_scope: :employers
        }
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

    end
  end
end
