module Effective
  module Datatables
    class DocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'Download'
          bulk_action 'Delete', data: {  confirm: 'Are you sure?', no_turbolink: true }
        end
        table_column :status, :proc => Proc.new { |row| "status" }, :filter => false, :sortable => false
        table_column :doc_type, :proc => Proc.new { |row| link_to "type","" }, :filter => false, :sortable => false
        table_column :effective_date, :proc => Proc.new { |row| "effective date" }, :filter => false, :sortable => false
        table_column :submitted_date, :proc => Proc.new { |row| "submitted date" }, :filter => false, :sortable => false
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        Document.all
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

      status_tab =  [
          {label: 'Submitted'},
          { label: 'Approved'},
          { label: 'Rejected'},
          { label: 'All'}
           ]

      {
          status: status_tab,
          top_scope: :status
      }
      end
    end
  end
end
