# frozen_string_literal: true

module Effective
  module Datatables
    class EmployerStaffDatatable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| link_to row.full_name, show_roles_person_path(id: row.id)}, :filter => false, :sortable => true
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.hbx_id }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| format_date(row.dob)}, :filter => false, :sortable => false
        table_column :email, :label => 'EMAIL', :proc => Proc.new { |row| email(row) }, :filter => false, :sortable => false
        table_column :phone, :label => 'PHONE', :proc => Proc.new { |row| phone(row)}, :filter => false, :sortable => false
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
