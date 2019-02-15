module Effective
  module Datatables
    class PlanDesignOrganizationDatatable < ::Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do
        table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row|
          if row.broker_relationship_inactive?
            row.legal_name
          else
            (link_to row.legal_name, eval(benefit_sponsor_home_url(row)))
          end
        }, :sortable => false, :filter => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| er_fein(row) }, :sortable => false, :filter => false
        table_column :ee_count, :label => 'EE Count', :proc => Proc.new { |row| ee_count(row) }, :sortable => false, :filter => false
        table_column :er_state, :label => 'ER State', :proc => Proc.new { |row| er_state(row) }, :sortable => false, :filter => false
        table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row|

          latest_plan_year = row.employer_profile.latest_plan_year if row.employer_profile.present?
          if latest_plan_year.blank?
            "No Active Plan"
          else
            latest_plan_year.start_on.strftime("%m/%d/%Y")
          end
        }, :sortable => false, :filter => false

        table_column :broker, :label => 'Broker', :proc => Proc.new { |row| broker_name(row) }, :sortable => false, :filter => false
        
        
        table_column :general_agency, :label => "General Agency", :proc => Proc.new { |row|
          general_agency_profile = row.general_agency_profile
          if general_agency_profile
            clear_assign_path =  raw('<br>') + link_to("clear assignment", main_app.clear_assign_for_employer_broker_agencies_profile_path(id: row.owner_profile_id, employer_id: row.sponsor_profile_id), method: :post, remote: true, data: {  confirm: "This will remove this General Agency assignment. Are you sure?" })
            general_agency = general_agency_profile.legal_name + clear_assign_path
          end
        }, :sortable => false, :filter => false if general_agency_enabled? && !on_general_agency_portal?

        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['View Quotes', sponsored_benefits.organizations_plan_design_organization_plan_design_proposals_path(row), 'ajax'],
           ['Create Quote', sponsored_benefits.new_organizations_plan_design_organization_plan_design_proposal_path(row), 'static'],
           ['Edit Employer Details', sponsored_benefits.edit_organizations_plan_design_organization_path(row), edit_employer_link_type(row)],
           ['Remove Employer', sponsored_benefits.organizations_plan_design_organization_path(row),
                              remove_employer_link_type(row),
                              "Are you sure you want to remove this employer?"]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employers_actions_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def remove_employer_link_type(employer)
        if employer.is_prospect?
          'delete with confirm'
        else
          return 'disabled'
        end
      end

      def edit_employer_link_type(employer)
        employer.is_prospect? ? 'ajax' : 'disabled'
      end

      def broker_name(row)
        row.broker_agency_profile.primary_broker_role.person.full_name
      end

      def ee_count(row)
        return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
        row.employer_profile.roster_size
      end

      def er_state(row)
        return 'N/A' if row.is_prospect?
        return 'Former Client' if row.broker_relationship_inactive?
        if dc?
          row.employer_profile.aasm_state.capitalize
        else
          sponsorship = row.employer_profile.organization.active_benefit_sponsorship
          sponsorship.aasm_state.capitalize
        end
      end

      def er_fein(row)
        return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
        row.fein
      end

      def benefit_sponsor_home_url(row)
        if dc?
          "main_app.employers_employer_profile_path(row.sponsor_profile_id, :tab=>'home')"
        else
          "benefit_sponsors.profiles_employers_employer_profile_path(row.sponsor_profile_id, tab: 'home')"
        end
      end

      def dc?
        aca_state_abbreviation == "DC"
      end

      def on_general_agency_portal?
        attributes[:is_general_agency]
      end

      def collection
        return @collection if (defined? @collection) && @collection.present?
        @collection = Queries::PlanDesignOrganizationQuery.new(attributes)
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def nested_filter_definition
        {
          filters:[
                { scope: 'all', label: 'All'},
                { scope: 'active_sponsors', label: 'Active'},
                { scope: 'inactive_sponsors', label: 'Inactive'},
                { scope: 'prospect_sponsors', label: "Prospects" }
              ],
          top_scope: :filters
        }
      end
    end
  end
end
