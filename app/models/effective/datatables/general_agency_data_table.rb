
module Effective
  module Datatables
    class GeneralAgencyDataTable < Effective::MongoidDatatable
      datatable do
        table_column :hbx_id, :label => 'HBX Acct', :proc => Proc.new { |row|  row.employer_profile.hbx_id }, :filter => false, :sortable => false
        table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row|  link_to row.employer_profile.legal_name, employers_employer_profile_path(row) + "?tab=home" }, :filter => false, :sortable => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| number_to_obscured_fein(row.employer_profile.fein) }, :filter => false, :sortable => false
        table_column :roster_size, :label => 'EE Ct', :proc => Proc.new { |row| row.employer_profile.roster_size  }, :filter => false, :sortable => false
        table_column :aasm_state, :label => 'Enroll Status', :proc => Proc.new { |row| row.employer_profile.aasm_state.humanize }, :filter => false, :sortable => false
        table_column :effective_date, :label => 'Effective Date', :proc => Proc.new {  |row| 
              row.employer_profile.published_plan_year.try(:effective_date) 
              link_to ' (Review)', employers_premium_statement_path(row)
                }, :filter => false, :sortable => false

        table_column :broker_agency_profile, :label => 'Broker Agency Name', :proc => Proc.new { |row| row.employer_profile.broker_agency_profile.organization.legal_name if row.employer_profile.broker_agency_profile.present? }, :filter => false, :sortable => false
      end

      def collection
        Organization.by_general_agency_profile(general_agency_profile.id)
      end

      def general_agency_profile
        GeneralAgencyProfile.find(attributes[:id])
      end

      def global_search?
        true
      end

      def nested_filter_definition
        
      end
    end
  end
end
