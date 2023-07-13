module Effective
  module Datatables
    class PlanDesignEmployeeDatatable < ::Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do

        bulk_actions_column do
          bulk_action 'Employee will enroll',  expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"enroll"), data: {confirm: 'These employees will be used to estimate your group size and participation rate', no_turbolink: true}
          bulk_action 'Employee will not enroll with valid waiver', expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"waive"), data: {confirm: 'Remember, your group size can affect your premium rates', no_turbolink: true}
          bulk_action 'Employee will not enroll with invalid waiver', expected_selection_plan_design_proposal_plan_design_census_employees_path(@plan_design_proposal.proposal, :expected_selection=>"will_not_participate"), data: {confirm: 'Remember, your participation rate can affect your group premium rates', no_turbolink: true}
        end

        table_column :employee_name, :width => '50px', :proc => Proc.new { |row|
          # @employer_profile = row.employer_profile
          # (link_to row.full_name, employers_employer_profile_census_employee_path(@employer_profile.id, row.id)) + raw("<br>")
          row.full_name
        }, :sortable => false, :filter => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row|
          row.dob.strftime("%m/%d/%Y")
        }, :sortable => false, :filter => false

        table_column :hired_on, :proc => Proc.new { |row|
          row.hired_on
        }, :sortable => false, :filter => false

        table_column :status, :proc => Proc.new { |row|
          row.aasm_state.titleize
        }, :sortable => false, :filter => false
        
        table_column :est_participation, :proc => Proc.new { |row|
          row.expected_selection.titleize if row.expected_selection
        }, :sortable => false, :filter => false

        table_column :census_dependents, :label => 'No. of Dependents', :proc => Proc.new { |row|
          row.census_dependents_count
        }, :sortable => false, :filter => false

        table_column :actions, label: "", :width => '50px', :proc => Proc.new { |row|
          # @employer_profile = row.employer_profile

          proposal = row.plan_design_proposal
          # Has to specify the valid route path for rehire and initiate cobra
          dropdown = [
              ['Edit', sponsored_benefits.edit_plan_design_proposal_plan_design_census_employee_path(proposal, row), 'ajax'],
              ['Delete', sponsored_benefits.plan_design_proposal_plan_design_census_employee_path(proposal, row), 'delete ajax with confirm and elementId', "Do you want to delete this employee?", "plan_design_employee_delete"],
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "plan_design_employee_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless  (defined? @employees) && @employees.present?   #memoize the wrapper class to persist @search_string
          @employees = Queries::PlanDesignEmployeeQuery.new(attributes)
        end
        @employees
      end

      # def cobra_possible? census_employee
      #   return 'disabled' if census_employee.cobra_linked?
      #   return 'disabled' if census_employee.cobra_eligible?
      #   return 'disabled' if census_employee.rehired?
      #   census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      # end

      # def rehire_possible? census_employee
      #   return 'disabled' if census_employee.cobra_linked?
      #   return 'disabled' if census_employee.cobra_eligible?
      #   return 'disabled' if census_employee.rehired?
      #   census_employee.active_or_pending_termination? ? 'ajax' : 'disabled'
      # end

      # def terminate_possible? census_employee
      #   census_employee.active_or_pending_termination? ? 'disabled' : 'ajax'
      # end

      def nested_filter_definition
          {
            employees:
                [
                    {scope: 'active_alone', label: 'Active only'},
                    {scope: 'active', label: 'Active & COBRA'},
                    {scope: 'by_cobra', label: 'COBRA only'},
                    # {scope: 'terminated', label: 'Terminated'},
                    {scope: 'all', label: 'All'}
                ],
            top_scope: :employees
        }
      end

      def matching_broker?(current_user, profile)
        current_user&.person&.broker_role.present? && current_user.person.broker_role.benefit_sponsors_broker_agency_profile_id == profile.id
      end

      def matching_ga_staff?(staff_roles, profile)
        profile.general_agency_accounts.any? do |acc|
          staff_roles.map(&:benefit_sponsors_general_agency_profile_id).include?(acc.benefit_sponsrship_general_agency_profile_id)
        end
      end

      def authorized?(current_user, _controller, _action, _resource)
        return false unless current_user
        return true if current_user.has_hbx_staff_role?

        profile = ::BenefitSponsors::Organizations::Profile.find(attributes[:profile_id]) || ::BrokerAgencyProfile.find(attributes[:profile_id]) || ::GeneralAgencyProfile.find(attributes[:profile_id])
        return false unless profile
        return true if matching_broker?(current_user, profile)
        return false if profile.general_agency_accounts.blank?

        staff_roles = current_user.person.active_general_agency_staff_roles
        return false if staff_roles.blank?

        matching_ga_staff?(staff_roles, profile)
      end
    end
  end
end
