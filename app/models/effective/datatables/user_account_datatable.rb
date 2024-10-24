module Effective
  module Datatables
    class UserAccountDatatable < Effective::MongoidDatatable
      include Config::SiteModelConcern
      include DropdownHelper

      datatable do
        table_column :oim_id, :label => l10n('hbx_profiles.user_accounts.table.username'), :proc => proc { |row| row.oim_id }, :filter => false, :sortable => true
        unless EnrollRegistry.feature_enabled?(:mask_ssn_ui_fields)
          table_column :ssn, :label => l10n('ssn'), :proc => proc { |row| truncate(number_to_obscured_ssn(row.person.ssn)) if row.person.present? }, :filter => false, :sortable => false
        end
        table_column :dob, :label => l10n('dob'), :proc => proc { |row| format_date(row.person.dob) if row.person.present?}, :filter => false, :sortable => false
        table_column :hbx_id, :label => l10n('hbx_id'), :proc => proc { |row| row.person.hbx_id if row.person.present?}, :filter => false, :sortable => false
        table_column :email, :label => l10n('hbx_profiles.user_accounts.table.user_email'), :proc => proc { |row| row.email }, :filter => false, :sortable => false
        table_column :status, :label => l10n('status'), :proc => proc { |row| status(row) }, :filter => false, :sortable => false
        table_column :role_type, :label => l10n('hbx_profiles.user_accounts.table.role_type'), :proc => proc { |row| all_roles(row) }, :filter => false, :sortable => false
        table_column :permission, :label => l10n('hbx_profiles.user_accounts.table.permission_level'), :proc => proc { |row| permission_type(row) }, :filter => false, :sortable => false
        table_column :actions, :label => l10n('actions'), :width => '50px', :proc => proc { |row|
          dropdown = []
          # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
          current_user_permission = current_user&.person&.hbx_staff_role&.permission
          dropdown << ['View Login History',login_history_user_path(id: row.id), 'ajax'] if current_user_permission&.view_login_history
          dropdown << ['Edit User', change_username_and_email_user_path(row.id, user_id: row.id.to_s), 'ajax'] if current_user_permission&.can_change_username_and_email
          if EnrollRegistry.feature_enabled?(:reset_password_lock_unlock_user)
            if current_user_permission&.can_reset_password && row.email.present?
              dropdown << ['Reset Password', reset_password_user_path(row), 'ajax']
            elsif current_user_permission&.can_reset_password
              dropdown << ['Reset Password', edit_user_path(row.id), 'ajax']
            end
            dropdown << ['Unlock / Lock Account', confirm_lock_user_path(row.id, user_action_id: "user_action_#{row.id}"), 'ajax'] if current_user_permission&.can_lock_unlock
          end
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: @bs4 ? map_legacy_dropdown(dropdown) : dropdown, row_actions_id: "user_action_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        unless (defined? @user_collection) && @user_collection.present? #memoize the wrapper class to persist @search_string
          @user_collection = Queries::UserDatatableQuery.new(attributes)
        end
        @user_collection
      end

      def status(row)
        return "Unlocked" if row.locked_at.blank? && row.unlock_token.blank?
        "Locked"
      end

      def permission_type(row)
        row&.person&.hbx_staff_role&.permission&.name || 'N/A'
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def nested_filter_definition
        {
          lock_unlock:
              [
                {scope: 'locked', label: 'Locked'},
                {scope: 'unlocked', label: 'Unlocked'}
              ],
          users:
              [{scope: 'all', label: 'All', subfilter: :lock_unlock}].tap do |a|
                a << {scope: 'all_employee_roles', label: 'Employee', subfilter: :lock_unlock} if is_shop_or_fehb_market_enabled?
                a << {scope: 'all_employer_staff_roles', label: 'Employer', subfilter: :lock_unlock} if is_shop_or_fehb_market_enabled?
                a << {scope: 'all_broker_roles', label: 'Broker', subfilter: :lock_unlock}
                a << {scope: 'all_consumer_roles', label: 'Consumer', subfilter: :lock_unlock}
              end,
          top_scope: :users
        }
      end

      def authorized?(current_user, _controller, _action, _resource)
        return nil unless current_user
        HbxProfilePolicy.new(current_user, nil).can_access_user_account_tab?
      end

      # Concatenates all active role names of a given user into a single comma-separated string.
      #
      # @param user [User] The user whose active roles are to be concatenated.
      # @return [String] A comma-separated string of all active role names for the user.
      def all_roles(user)
        user.all_active_role_names.join(', ')
      end
    end
  end
end
