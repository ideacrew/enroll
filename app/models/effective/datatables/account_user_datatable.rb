# frozen_string_literal: true

module Effective
  module Datatables
    # class for Keycloak AccountUserDatatable, used as an alternate to UserAccountDatatable
    class AccountUserDatatable < Effective::Datatable
      include Config::SiteModelConcern
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      include ActionView::Helpers::TextHelper
      include Config::AcaModelConcern

      datatable do
        table_column :name, :label => 'USERNAME', :filter => false, :sortable => true
        table_column :email, :label => 'USER EMAIL', :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :filter => false, :sortable => false
        table_column :status, :label => 'Status', :filter => false, :sortable => false
        table_column :role_type, :label => 'Role Type', :filter => false, :sortable => false
        table_column :permission, :label => 'Permission level', :filter => false, :sortable => false
        table_column :actions, :width => '50px', :filter => false, :sortable => false
      end

      def collection
        return @accounts_collection if defined?(@accounts_collection) && @accounts_collection.present?

        results = Operations::Accounts::Find.new.call(scope_name: :all, page_number: page, page_size: per_page).success
        @accounts_collection = if results.present?
                                 render_table_rows(results)
                               else
                                 [['None given']]
                               end
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def render_table_rows(results)
        result_ids = results.map { |result| result[:id] }
        users = User.where(:account_id.in => result_ids)
        results.reduce([]) do |memo, result|
          result_user = users.detect { |user| user.account_id == result[:id] }
          if result_user
            dropdown = [
              #['Forgot Password', user_account_forgot_password_path(user_id: result_user.id, account_id: result[:id], username: result[:username]), 'ajax'],
              ['Reset Password', user_account_reset_password_path(user_id: result_user.id, account_id: result[:id], username: result[:username]), 'ajax'],
              ['Unlock / Lock Account', user_account_lockable_path(user_id: result_user.id, account_id: result[:id], enabled: result[:enabled]), 'ajax'],
              ['View Login History',login_history_user_path(id: result_user.id), 'ajax'],
              ['Edit User', user_account_change_username_and_email_path(user_id: result_user.id, account_id: result[:id], username: result[:username], email: result[:email]), 'ajax']
            ]
            dropdown_html = ApplicationController.new.render_to_string(partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "user_action_#{result_user.id}"}, formats: :html)
            memo + [[
              result[:username],
              result[:email] || 'Unknown',
              truncate(number_to_obscured_ssn(result_user&.person&.ssn)) || 'Unknown',
              result_user&.person&.dob || 'Unknown',
              result_user&.person&.hbx_id || 'Unknown',
              result[:enabled] ? 'Unlocked' : 'Locked',
              (result_user&.roles || ['None']).join(', '),
              permission_type(result_user),
              dropdown_html
            ]]
          else
            memo
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def permission_type(user)
        user&.person&.hbx_staff_role&.permission&.name || 'N/A'
      end

      def total_records
        @total_records ||= count_total_records
      end

      def fetch_page_of_data
        results = if global_search_string.present?
                    @total_records = count_total_records
                    Operations::Accounts::Find.new.call(scope_name: :by_any, criterion: global_search_string.strip, page_number: page, page_size: per_page).success
                  else
                    Operations::Accounts::Find.new.call(scope_name: :all, page_number: page, page_size: per_page).success
                  end

        render_table_rows(results)
      end

      def array_tool_paginate(_col)
        fetch_page_of_data
      end

      def count_total_records
        if global_search_string.present?
          Operations::Accounts::Find.new.call(scope_name: :by_any, criterion: global_search_string.strip).success.length
        else
          Operations::Accounts::Find.new.call(scope_name: :count_all).success
        end
      end

      def global_search?
        true
      end
    end
  end
end
