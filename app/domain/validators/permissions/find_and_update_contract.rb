# frozen_string_literal: true

module Validators
  module Permissions
    # Validator class for finding and updating permissions contracts
    #
    # @note This list needs to be updated with the new permission field names as we add them to the Permission model
    class FindAndUpdateContract < ::Dry::Validation::Contract

      # Define the parameters for the contract
      #
      # @param names [Array<String>] the names of the permissions
      # @param field_name [Symbol] the field name to be updated
      # @param field_value [Boolean] the value to be set for the field
      params do
        required(:names).array(
          Types::Coercible::String,
          included_in?: ::Permission::PERMISSION_KINDS
        )

        # This list looks exhaustive, but we definitely need to add the full list of permissions here instead of taking a shortcut.
        # We always want to have Allow/Permitted List and not a Deny/Prohibited List for permission field names.
        required(:field_name).filled(
          Types::Coercible::Symbol,
          included_in?: [
            :modify_family,
            :modify_employer,
            :revert_application,
            :list_enrollments,
            :send_broker_agency_message,
            :approve_broker,
            :approve_ga,
            :modify_admin_tabs,
            :view_admin_tabs,
            :can_update_ssn,
            :can_complete_resident_application,
            :can_add_sep,
            :can_add_pdc,
            :can_lock_unlock,
            :can_view_username_and_email,
            :can_transition_family_members,
            :can_access_user_account_tab,
            :view_login_history,
            :can_change_username_and_email,
            :can_reset_password,
            :can_extend_open_enrollment,
            :can_modify_plan_year,
            :can_create_benefit_application,
            :can_change_fein,
            :can_force_publish,
            :view_the_configuration_tab,
            :can_submit_time_travel_request,
            :can_view_application_types,
            :view_personal_info_page,
            :can_access_new_consumer_application_sub_tab,
            :can_access_outstanding_verification_sub_tab,
            :can_access_identity_verification_sub_tab,
            :can_access_accept_reject_identity_documents,
            :can_access_accept_reject_paper_application_documents,
            :can_delete_identity_application_documents,
            :can_access_pay_now,
            :view_agency_staff,
            :manage_agency_staff,
            :can_access_age_off_excluded,
            :can_send_secure_message,
            :can_manage_qles,
            :can_edit_aptc,
            :can_view_sep_history,
            :can_reinstate_enrollment,
            :can_cancel_enrollment,
            :can_terminate_enrollment,
            :change_enrollment_end_date,
            :can_drop_enrollment_members,
            :can_call_hub,
            :can_edit_osse_eligibility,
            :can_edit_broker_agency_profile,
            :can_view_notice_templates,
            :can_edit_notice_templates,
            :can_view_audit_log
          ]
        )

        required(:field_value).filled(:bool)
      end
    end
  end
end
