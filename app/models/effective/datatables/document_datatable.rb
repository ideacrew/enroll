module Effective
  module Datatables
    class DocumentDatatable < Effective::MongoidDatatable
      datatable do
        
        bulk_actions_column do
          bulk_action 'Download'
          bulk_action 'Delete', data: {  confirm: 'Are you sure?', no_turbolink: true }
        end
        table_column :status, :proc => Proc.new { |row|
          row.employer_profile.employer_attestation.try(:aasm_state)
        }, :filter => false, :sortable => false
        table_column :employer, :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.legal_name.titleize, employers_employer_profile_path(@employer_profile, :tab=>'home'))
        }, :sortable => false, :filter => false
        table_column :doc_type, :proc => Proc.new { |row| link_to "Employer Attestation","", "data-toggle" => "modal", 'data-target' => "#employeeModal_#{row.id}"  }, :filter => false, :sortable => false
        table_column :effective_date, :proc => Proc.new { |row| "effective date" }, :filter => false, :sortable => false
        table_column :submitted_date, :proc => Proc.new { |row| "submitted date" }, :filter => false, :sortable => false
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        employers = Organization.all_employer_profiles
        if attributes[:aasm_state].present?
          ids = []
          employers.each do |e|
            if e.employer_profile.employer_attestation && e.employer_profile.employer_attestation.has_documents?
                if e.employer_profile.employer_attestation.aasm_state == attributes[:aasm_state]
                  ids << e
                end
            end
          end
          employers =  Organization.where(:_id.in => ids)
        end
        employers
      end

      def global_search?
        false
      end

      def global_search_method
        val = params[:search][:value]
        if val.match(/\d{9}/)
          :datatable_search_fein
        else
          :datatable_search
        end
      end

      def search_column(collection, table_column, search_term, sql_column)

      end

    def nested_filter_definition

      {
          top_scope:  :aasm_state,
          aasm_state: [
              {scope: "submitted",label: 'submitted'},
              {scope: "accepted",label: 'accepted'},
              {scope: "rejected",label: 'rejected'},
              {label: 'all'}
          ],
      }
      end
    end
  end
end
