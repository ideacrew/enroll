
module Effective
  module Datatables
    class ArrayBacked < Effective::Datatable
      datatable do


        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }
        end

        array_column :legal_name, :width => '25%'
        array_column :conversion
        array_column :state
        array_column :plan_year_state
        array_column :update_at, :proc => Proc.new { |row| row[5].strftime('%m/%d/%Y')}


      end

      def collection
        employers = Organization.all_employer_profiles
        employers.limit(50).map{|org|
         [
            org.fein,
            org.legal_name,
            org.employer_profile.is_conversion?,
            org.primary_office_location && org.primary_office_location.address.state,
            org.employer_profile.latest_plan_year.try(:aasm_state),
            org.employer_profile.updated_at
         ]}
      end

    end
  end
end
