module Effective
  module Datatables
    class QuoteDatatable < Effective::MongoidDatatable

      datatable do
      	table_column :quote, proc: Proc.new { |row| 
      	  link_to row.quote_name.titleize, broker_agencies_broker_role_quote_path(
      	    Effective::Datatables::QuoteDatatable.broker_role_id, row),
      	  data: { no_turbolink: true }      		},
      	  :sortable => false, :filter => false
      	table_column :claim_code, proc: Proc.new { |row| row.claim_code}, :sortable => false, :filter => false
      	table_column :family_count, proc: Proc.new { |row| row.quote_households.count}, :sortable => false, :filter => false
      	table_column :state, proc: Proc.new { |row| row.aasm_state}, :sortable => false, :filter => false
      end
      
      def collection
        quotes = Quote.where(broker_role_id: Effective::Datatables::QuoteDatatable.broker_role_id)

      end
   
      def global_search?
      	true
      end

      def nested_filter_definition
        {
          top_scope:  :states,
          states: [
            {scope: 'all', label: 'All'},
            {scope: 'draft', label: 'Draft'},
            {scope: 'published', label: 'Published'},
            {scope: 'claimed', label: 'Claimed'},
          ],
        }
      end

      class << self
      	attr_accessor :broker_role_id
      end

    end
  end
end