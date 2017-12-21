# module SponsoredBenefits
  module Effective
    module Datatables
      class BrokerAgencyEmployerDatatable < ::Effective::MongoidDatatable
        datatable do

          table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row| row.legal_name }, :sortable => false, :filter => false
          table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false
          table_column :ee_count, :label => 'EE Count', :proc => Proc.new { |row| row.employer_profile.roster_size }, :sortable => false, :filter => false
          table_column :er_state, :label => 'ER State', :proc => Proc.new { |row| row.employer_profile.aasm_state }, :sortable => false, :filter => false
          table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row| row.employer_profile.registered_on }, :sortable => false, :filter => false
          #table_column :broker, :label => 'Broker', :proc => Proc.new { |row| row.employer_profile.active_broker.full_name }, :sortable => false, :filter => false

          table_column :actions, :width => '50px', :proc => Proc.new { |row|
            dropdown = [
             # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
             #['Create Quote', new_broker_agencies_broker_role_quote_path(broker_role_id: BrokerAgencyEmployerDatatable.profile_id, id: row.id), 'static'],
             ['Create Quote', sponsored_benefits.broker_client_benefit_applications_path(broker_id: row.owner_profile_id, client_id: row.customer_profile_id), 'static'],
             ['Remove Quote', 'some-quote-remove-path', 'static']

            ]
            render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employers_actions_#{row.id.to_s}"}, formats: :html
          }, :filter => false, :sortable => false
        end

        scopes do
          scope :legal_name, "Hello"
        end

        class << self
        	attr_accessor :profile_id
        end

        def collection
          profile_id = attributes["collection_scope"] || BrokerAgencyEmployerDatatable.profile_id

          # Existing
          existing_employers = Organization.by_broker_agency_profile(profile_id)

          # Prospective
          prospective_employers = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(profile_id)

          return prospective_employers #for now
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


      end
    end
  end
# end
