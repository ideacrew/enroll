
module Effective
  module Datatables
    class IdentityVerificationDataTable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| link_to row.full_name, identity_verification_pending_admin_approval_exchanges_hbx_profiles_path(:person_id => row.id) }, :filter => false, :sortable => false
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
