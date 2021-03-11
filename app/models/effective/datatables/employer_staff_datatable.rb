# frozen_string_literal: true

module Effective
  module Datatables
    # This class categorize the employer staff data fields in table columns.
    class EmployerStaffDatatable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => proc { |row| link_to row.full_name, show_roles_person_path(id: row.id)}, :filter => false, :sortable => true
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| row.hbx_id }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => proc { |row| format_date(row.dob)}, :filter => false, :sortable => false
        table_column :email, :label => 'EMAIL', :proc => proc { |row| email(row) }, :filter => false, :sortable => false
        table_column :phone, :label => 'PHONE', :proc => proc { |row| phone(row)}, :filter => false, :sortable => false
      end

      def collection
        return @collection if defined? @collection
        @collection = Queries::EmployerStaffDatatableQuery.new(attributes)
        @collection
      end

      def permission_type(row)
        row&.hbx_staff_role&.permission&.name || 'N/A'
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def email(row)
        row.emails.first.address if row.emails.present?
      end

      def phone(row)
        row.phones.first.full_phone_number if row.phones.present?
      end
    end
  end
end
