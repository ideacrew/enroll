# module SponsoredBenefits
  module Effective
    module Datatables
      class PlanDesignProposalsDatatable < ::Effective::MongoidDatatable
        datatable do

          table_column :title, :label => 'Quote Name', :proc => Proc.new { |row|
              if row.published?
                ## will become link to view-only page
                row.title
              else
                link_to row.title, sponsored_benefits.edit_organizations_plan_design_organization_plan_design_proposal_path(row.plan_design_organization, row)
              end
              }, :sortable => false, :filter => false
          table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row| proposal_sponsorship(row).initial_enrollment_period.begin.strftime("%Y - %m - %d") }, :sortable => true, :filter => false
          table_column :claim_code, :label => 'Claim Code', :proc => Proc.new { |row| row.claim_code || 'Not Published' }, :sortable => false, :filter => false
          table_column :employees, :label => 'Employees', :proc => Proc.new { |row| proposal_sponsorship(row).census_employees.count }, :sortable => false, :filter => false
          table_column :families, :label => "Families", :proc => Proc.new { |row| proposal_sponsorship(row).census_employees.where({ "census_dependents.0" => { "$exists" => true } }).count }, :sortable => false, :filter => false
          table_column :state, :label => 'State', :proc => Proc.new { |row| row.aasm_state.capitalize }, :sortable => false, :filter => false

          #table_column :claim_date, :label => 'Claim Date', :proc => Proc.new { |row| row.claim_date }, :sortable => false, :filter => false
          #table_column :broker, :label => 'Broker', :proc => Proc.new { |row| row.employer_profile.active_broker.full_name }, :sortable => false, :filter => false

          table_column :actions, :width => '50px', :proc => Proc.new { |row|
            dropdown = [
             # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
             ['Edit Quote', sponsored_benefits.edit_organizations_plan_design_organization_plan_design_proposal_path(row.plan_design_organization.id, row.id), 'static'],
             ['Publish Quote', sponsored_benefits.organizations_plan_design_proposal_publish_path(row.id), 'post_ajax'],
             ['Remove Quote', sponsored_benefits.organizations_plan_design_proposal_path(row.id), 'delete with confirm', "Are you sure? This will permanently delete the quote information"]
            ]
            render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "quotes_actions_#{row.id.to_s}"}, formats: :html
          }, :filter => false, :sortable => false
        end

        def proposal_sponsorship(row)
          row.profile.benefit_sponsorships.first
        end

        class << self
        	attr_accessor :organization_id
        end

        def collection
          unless (defined? @quotes) && @quotes.present?
            @quotes = Queries::PlanDesignProposalsQuery.new(attributes)
          end
          @quotes
        end

        def global_search?
          true
        end

        def global_search_method
          :datatable_search
        end

        def search_column(collection, table_column, search_term, sql_column)
          # if table_column[:name] == 'legal_name'
          #   collection.datatable_search(search_term)
          # elsif table_column[:name] == 'fein'
          #   collection.datatable_search_fein(search_term)
          # else
          #   super
          # end
        end

        def nested_filter_definition
          {
            quotes:[
                  { scope: 'all', label: 'All'},
                  { scope: 'initial', label: 'Initial'},
                  { scope: 'draft', label: "Draft" },
                  { scope: 'published', label: "Published" },
                  { scope: 'expired', label: "Expired" },
                ],
            top_scope: :quotes
          }
        end


      end
    end
  end
# end
