# module SponsoredBenefits
  module Effective
    module Datatables
      class BrokerAgencyEmployerDatatable < ::Effective::MongoidDatatable
        datatable do

          table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row|
            if row.broker_relationship_inactive?
              row.legal_name
            else
              (link_to row.legal_name, main_app.employers_employer_profile_path(id: row.customer_profile_id, :tab=>'home'))
            end
            }, :sortable => false, :filter => false
          table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false
          table_column :ee_count, :label => 'EE Count', :proc => Proc.new { |row| ee_count(row) }, :sortable => false, :filter => false
          table_column :er_state, :label => 'ER State', :proc => Proc.new { |row| er_state(row) }, :sortable => false, :filter => false
          table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row| row.try(:employer_profile).try(:registered_on) }, :sortable => false, :filter => false
          #table_column :broker, :label => 'Broker', :proc => Proc.new { |row| row.employer_profile.active_broker.full_name }, :sortable => false, :filter => false

          table_column :actions, :width => '50px', :proc => Proc.new { |row|
            dropdown = [
             # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
             #['Create Quote', new_broker_agencies_broker_role_quote_path(broker_role_id: BrokerAgencyEmployerDatatable.profile_id, id: row.id), 'static'],
             ['Create Quote', sponsored_benefits.plan_design_organization_plan_design_proposals_path(plan_design_organization_id: row._id), 'static'],
             ['Remove Quote', 'some-quote-remove-path', 'static']

            ]
            render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employers_actions_#{row.id.to_s}"}, formats: :html
          }, :filter => false, :sortable => false
        end

        scopes do
          scope :legal_name, "Hello"
        end

        def ee_count(row)
          return 'N/A' if row.is_prospect?
          row.employer_profile.roster_size
        end

        def er_state(row)
          return 'N/A' if row.is_prospect?
          row.employer_profile.aasm_state.capitalize
        end

        class << self
        	attr_accessor :profile_id
        end

        def collection
          unless (defined? @employers) && @employers.present?
            @employers = Queries::PlanDesignOrganizationQuery.new(attributes)
          end
          @employers
        end

        def global_search?
          true
        end

        def global_search_method
          :datatable_search
        end

        def search_column(collection, table_column, search_term, sql_column)
          if table_column[:name] == 'legal_name'
            collection.datatable_search(search_term)
          elsif table_column[:name] == 'fein'
            collection.datatable_search_fein(search_term)
          else
            super
          end
        end

        def nested_filter_definition
          {
            clients:[
                  { scope: 'all', label: 'All'},
                  { scope: 'active_clients', label: 'Active'},
                  { scope: 'inactive_clients', label: 'Inactive'},
                  { scope: 'prospect_employers', label: "Prospects" }
                ],
            top_scope: :clients
          }
        end


      end
    end
  end
# end
