module Effective
  module Datatables
    class EmployerDocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          #bulk_action 'Download', download_documents_employers_employer_profile_path, data: {  confirm: 'Do you want to Download?', no_turbolink: true }
          bulk_action 'Delete', delete_documents_employers_employer_profile_path, data: {  confirm: 'Are you sure?', no_turbolink: true }
        end

        table_column :status, :proc => Proc.new { |row| 
          icon = ""

          if row.accepted?
            icon = "<span class='glyphicon glyphicon-ok text-success' aria-hidden='true' title='Approved'></span> "
          elsif row.reason_for_rejection.present?
            icon = "<span class='glyphicon glyphicon-exclamation-sign text-danger' aria-hidden='true' title='#{row.reason_for_rejection}'></span> "
          end

          raw(icon) + row.aasm_state.humanize 
        }, :filter => false, :sortable => false
        table_column :name, :label => 'Doc Name', :proc => Proc.new { |row|
          link_to raw('<i class="fa fa-file-text-o pull-left"></i> ') + row.title, "", 'target' => "iframe_#{row.id}", 'data-target' => "#employeeModal_#{row.id}", "data-toggle" => "modal", 'class' => 'pull-left'
        }, :filter => false, :sortable => false
        table_column :type, :label => 'Doc Type',:proc => Proc.new { |row|
           'Employer Attestation'
        }, :filter => false, :sortable => false
        table_column :size, :proc => Proc.new { |row| number_to_human_size(row.size, precision: 2) }, :filter => false, :sortable => false
        table_column :date, :label => 'Submitted At', :proc => Proc.new { |row| row.created_at.in_time_zone("Eastern Time (US & Canada)").strftime('%m/%d/%Y %I:%M%p') }, :filter => false, :sortable => false
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        @employer_profile = EmployerProfile.find(attributes[:employer_profile_id])
        documents = EmployerAttestationDocument.none
        if @employer_profile.employer_attestation.present?
          documents = @employer_profile.employer_attestation.employer_attestation_documents
        end
        documents
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

    end
  end
end
