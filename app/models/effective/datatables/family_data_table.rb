
module Effective
  module Datatables
    class FamilyDataTable < Effective::MongoidDatatable
      datatable do
        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }
        end
        table_column :family_hbx_id, :proc => Proc.new { |row| row.hbx_assigned_id }, :filter => false, :sql_column => "hbx_id"
        table_column :name, :proc => Proc.new { |row| link_to row.primary_applicant.person.full_name, resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id)}, :filter => false, :sortable => false
        table_column :ssn, :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.primary_applicant.person.ssn)) }, :filter => false, :sortable => false
        table_column :dob, :proc => Proc.new { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :proc => Proc.new { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :family_ct, :width => '100px', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :registered?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.user.present? ? "Yes" : "No"} , :filter => false, :sortable => false
        table_column :consumer?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.consumer_role.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :employee?, :width => '100px', :proc => Proc.new { |row| row.primary_applicant.person.active_employee_roles.present?  ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|  
          dropdown = [
           ['Add SEP', add_sep_form_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['View SEP History', show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Static Link', '/some-static-link', 'static'],
           ['Disabled Link','#', 'disabled' ]
          ]
          render '/datatables/shared/dropdown', dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"
        }, :filter => false, :sortable => false
      end

      scopes do
         scope :legal_name, "Hello"
      end

      def collection
        unless  (defined? @families) && @families.present?   #memoize the wrapper class to persist @search_string
          @families = Queries::FamilyDatatableQuery.new(attributes)
        end
        @families
      end

      def global_search?
        true
      end

      def nested_filter_definition
        {
        employer_options: [
          {scope: 'all', label: 'All'},
          {scope: 'enrolled', label: 'Enrolled'},
          {scope: 'by_enrollment_renewing', label: 'Renewing'},
          {scope: 'waived', label: 'Waived'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
          individual_options: [
            {scope: 'all', label: 'All'},
            {scope: 'all_assistance_receiving', label: 'Assisted'},
            {scope: 'unassisted', label: 'Unassisted'},
            {scope: 'cover_all', label: 'Cover All'},
            {scope: 'sep_eligible', label: 'SEP Eligible'}
          ],
          families:
            [
              {scope: 'all', label: 'All'},
              {scope: 'by_enrollment_individual_market', label: 'Individual Enrolled', subfilter: :individual_options},
              {scope: 'by_enrollment_shop_market', label: 'Employer Sponsored Coverage Enrolled', subfilter: :employer_options},
              {scope: 'non_enrolled', label: 'Non Enrolled'},
            ],
          top_scope: :families
        }
      end
    end
  end
end
