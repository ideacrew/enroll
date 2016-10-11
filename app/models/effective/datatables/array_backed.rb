
module Effective
  module Datatables
    class ArrayBacked < Effective::MongoidDatatable
      datatable do


        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }, :sortable => false
        end

        table_column :legal_name, :width => '200px', :proc => Proc.new { |row| link_to row.legal_name.titleize, employers_employer_profile_path(row.employer_profile, :tab=>'home')}, :sortable => false
        table_column :hbx_id, :width => '100px', :proc => Proc.new { |row| truncate(row.id.to_s, length: 8, omission: '' ) }, :sortable => false
        table_column :fein, :width => '100px', :proc => Proc.new { |row| row.fein }, :sortable => false
        table_column :plan_year_status, :proc => Proc.new { |row| row.employer_profile.renewing_plan_year.present? ? 'Renewing' : 'New'}, :sortable => false
        table_column :conversion,:proc => Proc.new { |row| boolean_to_glyph(row.employer_profile.is_conversion?)}, :filter => {:as => :select, :collection => ['Yes', 'No']}, :sortable => false
        table_column :state,:proc => Proc.new { |row| row.primary_office_location.try(:address).try(:state)} , :filter => false
        table_column :plan_year_state,:proc => Proc.new { |row| row.employer_profile.try(:latest_plan_year).try(:aasm_state)}, :filter => false
        #table_column :update_at, :proc => Proc.new { |row| row[5].strftime('%m/%d/%Y')}


      end


      def collection
        #binding.pry
        employers = Organization.all_employer_profiles
      end

      def global_search?
        true
      end

      def search_column(collection, table_column, search_term, sql_column)
        if table_column[:name] == 'fein'
          collection.datatable_search_fein(search_term)
        elsif table_column[:name] == 'conversion'
          collection.where("employer_profile.profile_source" => (search_term == 'Yes' ? "conversion" : "self_serve"))
        else
          super
        end
      end

    end
  end
end
