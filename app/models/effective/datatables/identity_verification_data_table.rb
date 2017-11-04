
module Effective
  module Datatables
    class IdentityVerificationDataTable < Effective::MongoidDatatable
      datatable do
        #table_column :family_hbx_id, :proc => Proc.new { |row| row.hbx_assigned_id }, :filter => false, :sql_column => "hbx_id"
        table_column :name, :label => 'Name', :proc => Proc.new { |row| row.full_name }, :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.ssn))}, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| row.dob }, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => Proc.new {  }, :filter => false, :sortable => false
        table_column :document_type, :label => 'Dcument Type', :proc => Proc.new { }, :filter => false, :sortable => false
        table_column :date_uploaded, :label => "Date Uploaded", :width => '100px', :proc => Proc.new { } , :filter => false, :sortable => false
      end

      scopes do
         scope :legal_name, "Hello"
      end

      def collection
        unless  (defined? @families) && @families.present?   #memoize the wrapper class to persist @search_string
          @families = Queries::IdentityVerificationDatatableQuery.new(attributes)
        end
        @families
      end

      def global_search?
        true
      end

    end
  end
end
