
module Effective
  module Datatables
    class ArrayBacked < Effective::MongoidDatatable
      datatable do


        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }
        end

        table_column :legal_name, :width => '25%'
        table_column :conversion,:proc => Proc.new { |row| 1}
        table_column :state,:proc => Proc.new { |row| row.primary_office_location.try(:address).try(:state)} , :filter => false, :sortable => false
        table_column :plan_year_state,:proc => Proc.new { |row| 1}
        #table_column :update_at, :proc => Proc.new { |row| row[5].strftime('%m/%d/%Y')}


      end

      def collection
        employers = Organization.all_employer_profiles
      end

      def global_search?
        true
      end


    end
  end
end
