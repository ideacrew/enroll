module Effective
  module Datatables
    class EmployerDocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'Download', download_documents_employers_employer_profile_path, data: {  confirm: 'Do you want to Download?', no_turbolink: true }
          bulk_action 'Delete', delete_documents_employers_employer_profile_path, data: {  confirm: 'Are you sure?', no_turbolink: true }
        end

        table_column :Status, :proc => Proc.new { |row| '<i class="fa fa-file-text-o" style="margin-right:20px;"></i> status' }, :filter => false, :sortable => false
        table_column :Name, :proc => Proc.new { |row| link_to row.title,"Dcoument", "data-toggle" => "modal", 'data-target' => "#employeeModal_#{row.id}" }, :filter => false, :sortable => false
        table_column :Type, :proc => Proc.new { |row| row.subject }, :filter => false, :sortable => false
        table_column :Size, :proc => Proc.new { |row| row.size_bytes_to_megabytes }, :filter => false, :sortable => false
        table_column :Date, :proc => Proc.new { |row| row.date }, :filter => false, :sortable => false
        table_column :Owner, :proc => Proc.new { |row| row.creator }, :filter => false, :sortable => false
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        @employer_profile = EmployerProfile.find(attributes[:employer_profile_id])
        @employer_profile.documents.all
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
