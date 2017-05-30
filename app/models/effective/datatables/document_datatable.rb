module Effective
  module Datatables
    class DocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'Download'
          bulk_action 'Delete', data: {  confirm: 'Are you sure?', no_turbolink: true }
        end
        table_column :Status, :proc => Proc.new { |row| '<i class="fa fa-file-text-o" style="margin-right:20px;"></i> status' }, :filter => false, :sortable => false
        table_column :Name, :proc => Proc.new { |row| link_to row.legal_name,"Dcoument", "data-toggle" => "modal", 'data-target' => '#employeeModal' }, :filter => false, :sortable => false
        table_column :Type, :proc => Proc.new { |row| link_to "Employer Attestation" }, :filter => false, :sortable => false
        table_column :Size, :proc => Proc.new { |row| "3MB" }, :filter => false, :sortable => false
        table_column :Date, :proc => Proc.new { |row| "05/26/2017" }, :filter => false, :sortable => false
        table_column :Owner, :proc => Proc.new { |row| "D Thomas" }, :filter => false, :sortable => false
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        employers = Organization.all_employer_profiles
        @employer_collection = employers
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
