module Effective
  module Datatables
    class EmployerDocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          #bulk_action 'Download', download_documents_employers_employer_profile_path, data: {  confirm: 'Do you want to Download?', no_turbolink: true }
          bulk_action 'Delete', delete_documents_employers_employer_profile_path, data: {  confirm: 'Are you sure?', no_turbolink: true }
        end

        table_column '', :proc => Proc.new { |row| '<i class="fa fa-file-text-o" style="margin-right:20px;"></i>' }, :filter => false, :sortable => false
        table_column :status, :proc => Proc.new { |row| row.aasm_state }, :filter => false, :sortable => false
        table_column :type, :proc => Proc.new { |row|
          @employer_profile = EmployerProfile.find(attributes[:employer_profile_id])
          link_to(row.title, employers_employer_attestation_authorized_download_path(row.id) + "?id=#{@employer_profile.id}&content_type=#{row.format}&filename=#{row.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline", class: "sbc_link", :target => "_blank") 
        }, :filter => false, :sortable => false
        table_column :name, :proc => Proc.new { |row| link_to 'Employer Attestation', "Document", "data-toggle" => "modal", 'data-target' => "#employeeModal_#{row.id}" }, :filter => false, :sortable => false
        table_column :size, :proc => Proc.new { |row| row.size_bytes_to_megabytes }, :filter => false, :sortable => false
        table_column :date, :proc => Proc.new { |row| row.created_at.strftime('%m/%d/%Y') }, :filter => false, :sortable => false
        table_column :owner, :proc => Proc.new { |row| row.creator }, :filter => false, :sortable => false
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
