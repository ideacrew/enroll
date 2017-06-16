module Effective
  module Datatables
    class UserAccountDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'action 1', nil, data: { confirm: 'Generate Invoices?', no_turbolink: true }
          bulk_action 'action 2', nil, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
        end
        table_column :name, :label => 'Name', :proc => Proc.new { |row| row.person.full_name if row.person.present? }, :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.person.ssn)) if row.person.present? }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| format_date(row.person.dob) if row.person.present?}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.person.hbx_id if row.person.present?}, :filter => false, :sortable => false
        table_column :email, :label => 'EMAIL', :proc => Proc.new { |row| row.email }, :filter => false, :sortable => false
        table_column :status, :label => 'Status', :proc => Proc.new { |row| status(row) }, :filter => false, :sortable => false
        table_column :role_type, :label => 'Role Type', :proc => Proc.new { |row| row_role(row) if row.person.present? }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['Reset Password', show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax'],
           ['Unlock / Lock Account', confirm_lock_user_path(row.id, user_action_id: "user_action_#{row.id.to_s}"), 'ajax'],
           ['View Login History',show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id.to_s}"), 'ajax']
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "user_action_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        return @user_collection if defined? @user_collection
        users = User.all
        @user_collection = users
      end

      def status(row)
        return "Unlocked" if row.locked_at.blank? && row.unlock_token.blank?
        "Locked"
      end

      def row_role(row)
        return "Employer staff role" if row.has_employer_staff_role?
        return "Employee" if row.has_employee_role?
        return "Broker" if row.has_broker_role?
        return "Broker Agency Staff" if row.has_broker_agency_staff_role?
        return "General Agency Staff" if row.has_general_agency_staff_role?
        return "Hbx Staff" if row.has_hbx_staff_role?
      end

      def global_search?
        true
      end

      def nested_filter_definition
        filters = {
          lock_unlock:
          [
            {scope:'locked', label: 'Locked'},
            {scope:'unlocked', label: 'Unlocked'},
          ],
          users:
          [
            {scope:'all', label: 'All', subfilter: :lock_unlock},
            {scope:'all_employee_roles', label: 'Employee', subfilter: :lock_unlock},
            {scope:'all_employer_staff_roles', label: 'Employer', subfilter: :lock_unlock},
            {scope:'all_broker_roles', label: 'Broker', subfilter: :lock_unlock},
          ],
        top_scope: :users
        }

      end
    end
  end
end