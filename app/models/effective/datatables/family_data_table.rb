# frozen_string_literal: true

module Effective
  module Datatables
    #Family datatable with options
    class FamilyDataTable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      include Config::SiteModelConcern
      include ApplicationHelper
      include HtmlScrubberUtil

      datatable do
        #table_column :family_hbx_id, :proc => Proc.new { |row| row.hbx_assigned_id }, :filter => false, :sql_column => "hbx_id"
        table_column :name, :label => 'Name', :proc => proc { |row|
          link_to_with_noopener_noreferrer(
            h(row.primary_applicant.person.full_name),
            resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id)
          )
        }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => proc { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :external_app_id, :label => 'External ID', :proc => proc { |row| row.external_app_id }, :filter => false, :sortable => false if EnrollRegistry[:display_external_id_in_family_datatable].enabled?
        table_column :count, :label => 'Count', :width => '100px', :proc => proc { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :active_enrollments, :label => 'Active Enrollments?', :proc => proc { |row| active_admin_dt_enrollments(row).any? ? "Yes" : "No"}, :filter => false, :sortable => false
        table_column :registered?, :width => '100px', :proc => proc { |row| row.primary_applicant.person.user.present? ? "Yes" : "No"}, :filter => false, :sortable => false
        if is_individual_market_enabled?
          table_column :consumer?, :width => '100px', :proc => proc { |row| row.primary_applicant.person.consumer_role.present? ? "Yes" : "No"}, :filter => false, :sortable => false
        end
        if is_shop_or_fehb_market_enabled?
          table_column :employee?, :width => '100px', :proc => proc { |row| row.primary_applicant.person.active_employee_roles.present? ? "Yes" : "No"}, :filter => false, :sortable => false
        end
        table_column :actions, :width => '50px', :proc => proc { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['Add SEP', add_sep_form_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id}"),
            add_sep_link_type(pundit_allow(HbxProfile, :can_add_sep?))],
           ['Create Eligibility', new_eligibility_exchanges_hbx_profiles_path(person_id: row.primary_applicant.person.id,
                                                                              family: row.id, family_actions_id: "family_actions_#{row.id}"), new_eligibility_family_member_link_type(row, pundit_allow(HbxProfile, :can_add_pdc?))],
           [sanitize_html("<div class='#{pundit_class(Family, :can_view_sep_history?)}'> View SEP History </div>"), show_sep_history_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id}"), 'ajax'],
           ['Cancel Enrollment', cancel_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id}"), cancel_enrollment_type(row, pundit_allow(Family, :can_cancel_enrollment?))],
           #cancel_enrollment_type(row, pundit_allow(Family, :can_update_ssn?))],
           ['Terminate Enrollment', terminate_enrollment_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id}"), terminate_enrollment_type(row, pundit_allow(Family, :can_terminate_enrollment?))],
           #terminate_enrollment_type(row, pundit_allow(Family, :can_update_ssn?))],
           ['Change Enrollment End Date', view_enrollment_to_update_end_date_exchanges_hbx_profiles_path(family: row.id, person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"),
            update_terminated_enrollment_type(row, pundit_allow(Family, :change_enrollment_end_date?))],
           ['Reinstate', view_terminated_hbx_enrollments_exchanges_hbx_profiles_path(family: row.id, person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"),
            reinstate_enrollment_type(row, pundit_allow(Family, :can_reinstate_enrollment?))],
           [sanitize_html("<div class='#{pundit_class(Family, :can_update_ssn?)}'> Edit DOB / SSN </div>"), edit_dob_ssn_path(id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"), 'ajax'],
           ['View Username and Email', get_user_info_exchanges_hbx_profiles_path(person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"),
            (individual_market_is_enabled? && pundit_allow(Family, :can_view_username_and_email?)) ? 'ajax' : 'disabled'],
           ['Collapse Form', hide_form_exchanges_hbx_profiles_path(family_id: row.id, person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"), no_transition_families_is_enabled? ? 'ajax' : '']
           ]

          if ::EnrollRegistry.feature_enabled?(:drop_enrollment_members)
            dropdown.insert(5,
                            [l10n('admin_actions.drop_enrollment_members'),
                             drop_enrollment_member_exchanges_hbx_profiles_path(family: row.id, family_actions_id: "family_actions_#{row.id}", admin_permission: pundit_allow(Family, :can_drop_enrollment_members?)),
                             drop_enrollment_member_type(row, pundit_allow(Family, :can_drop_enrollment_members?))])
          end

          if ::EnrollRegistry.feature_enabled?(:send_secure_message_family)
            dropdown.insert(8, ['Send Secure Message', new_secure_message_exchanges_hbx_profiles_path(person_id: row.primary_applicant.person.id, family_actions_id: "family_actions_#{row.id}"),
                                pundit_allow(HbxProfile, :can_send_secure_message?) ? "ajax" : "hide"])
          else
            dropdown.insert(8, ['Send Secure Message',
                                new_insured_inbox_path(id: row.primary_applicant.person.id,
                                                       profile_id: current_user.person.hbx_staff_role.hbx_profile.id,
                                                       to: "#{row.primary_applicant.person.last_name},
                                                       #{row.primary_applicant.person.first_name}",
                                                       family_actions_id: "family_actions_#{row.id}"),
                                secure_message_link_type(row, current_user)])
          end

          dropdown += if individual_market_is_enabled?
                        [
                          [l10n('admin_actions.edit_aptc_csr'), edit_aptc_csr_path(family_id: row.id, person_id: row.primary_applicant.person.id),
                           aptc_csr_link_type(row, pundit_allow(Family, :can_edit_aptc?))],
                          ['Paper', resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id, original_application_type: 'paper'), no_transition_families_is_enabled? ? 'static' : ''],
                          ['Phone', resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id, original_application_type: 'phone'), no_transition_families_is_enabled? ? 'static' : '']
                        ]
                      end

          if no_transition_families_is_enabled?
            dropdown << ['Transition Family Members', transition_family_members_insured_families_path(family: row.id, family_actions_id: "family_actions_#{row.id}"),
                         transition_family_members_link_type(row, pundit_allow(Family, :can_transition_family_members?)) ? 'ajax' : 'disabled']
          end

          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      scopes do
        scope :legal_name, "Hello"
      end

      def collection
        @families = Queries::FamilyDatatableQuery.new(attributes) unless (defined? @families) && @families.present? #memoize the wrapper class to persist @search_string
        @families
      end

      def global_search?
        true
      end

      def secure_message_link_type(family, current_user)
        person = family.primary_applicant.person
        ((person.user.present? || person.emails.present?) && current_user.person.hbx_staff_role) ? 'ajax' : 'disabled'
      end

      def aptc_csr_link_type(family, allow)
        # return "disabled" # DISABLING APTC FEATURE.
        family.active_household.latest_active_tax_household.present? && allow ? 'ajax' : 'disabled'
      end

      def add_sep_link_type(allow)
        allow ? 'ajax' : 'disabled'
      end

      def active_admin_dt_enrollments(row)
        row.admin_dt_enrollments.select do |en|
          (en.household_id == row.active_household.id) &&
            en.is_admin_active_enrolled_and_renewing?
        end
      end

      def reinstate_enrollment_type(family, allow)
        return 'disabled' unless allow
        reinstate_eligibles = family.admin_dt_enrollments.any?(&:is_admin_reinstate_or_end_date_update_eligible?)
        reinstate_eligibles ? 'ajax' : 'disabled'
      end

      def update_terminated_enrollment_type(family, allow)
        return 'disabled' unless allow
        end_date_update_eligibles = family.admin_dt_enrollments.any?(&:is_admin_reinstate_or_end_date_update_eligible?)
        end_date_update_eligibles ? 'ajax' : 'disabled'
      end

      def cancel_enrollment_type(family, allow)
        return 'disabled' unless allow
        cancel_eligibles = family.admin_dt_enrollments.any?(&:is_admin_cancel_eligible?)
        cancel_eligibles ? 'ajax' : 'disabled'
      end

      def terminate_enrollment_type(family, allow)
        return 'disabled' unless allow
        terminate_eligibles = family.admin_dt_enrollments.any?(&:is_admin_terminate_eligible?)
        terminate_eligibles ? 'ajax' : 'disabled'
      end

      def drop_enrollment_member_type(family, allow)
        # Don't return disabled for permission check, all admins can see this tool
        # return 'disabled' unless allow
        ivl_enrollments = family.hbx_enrollments.individual_market.select{ |enr| enr.is_admin_terminate_eligible? && enr.hbx_enrollment_members.count > 1 }
        ivl_enrollments.any? ? 'ajax' : 'disabled'
      end

      def new_eligibility_family_member_link_type(row, allow)
        allow && row.primary_applicant.person.has_active_consumer_role? ? 'ajax' : 'disabled'
      end

      def nested_filter_definition
        families_tab = [
          {scope: 'all', label: 'All'},
          {scope: 'non_enrolled', label: 'Non Enrolled'}
        ]
        families_tab.insert(1, {scope: 'by_enrollment_individual_market', label: 'Individual Enrolled', subfilter: :individual_options}) if individual_market_is_enabled?
        families_tab.insert(2, {scope: 'by_enrollment_shop_market', label: 'Employer Sponsored Coverage Enrolled', subfilter: :employer_options}) if ::EnrollRegistry[:aca_shop_market].enabled?

        {
          employer_options: [
            {scope: 'all', label: 'All'},
            {scope: 'enrolled', label: 'Enrolled'},
            {scope: 'by_enrollment_renewing', label: 'Renewing'},
            {scope: 'waived', label: 'Waived'},
            {scope: 'sep_eligible', label: 'SEP Eligible'}
          ],
          individual_options: [
          {scope: 'all', label: 'All'},
          {scope: 'all_assistance_receiving', label: 'Assisted'},
          {scope: 'all_unassisted', label: 'Unassisted'},
          {scope: 'sep_eligible', label: 'SEP Eligible'}
        ],
          families: families_tab,
          top_scope: :families
        }
      end

      def authorized?(current_user, _controller, _action, _resource)
        current_user.has_hbx_staff_role?
      end
    end
  end
end
