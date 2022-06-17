# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    modify_family { true }
    modify_employer { true }
    revert_application { true }
    list_enrollments { true }
    send_broker_agency_message { true }
    approve_broker { true }
    approve_ga { true }
    modify_admin_tabs { true }
    view_admin_tabs  { true }
    can_lock_unlock { false }
    can_reset_password { false }
    can_add_pdc { false }
    can_transition_family_members { true }
    can_view_sep_history {true}
    can_reinstate_enrollment {false}
    can_cancel_enrollment {false}
    can_terminate_enrollment {false}
    change_enrollment_end_date {false}
    can_drop_enrollment_members {false}

    trait :hbx_staff do
      name { 'hbx_staff' }
      can_complete_resident_application { true }
      can_add_sep { true }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_new_consumer_application_sub_tab { true }
      can_access_identity_verification_sub_tab { true }
      can_access_outstanding_verification_sub_tab { true }
      can_access_age_off_excluded {true}
      can_edit_aptc {true}
      can_reinstate_enrollment {true}
      can_cancel_enrollment {true}
      can_terminate_enrollment {true}
      change_enrollment_end_date {true}
      can_drop_enrollment_members {true}
      can_call_hub {true}
    end

    trait :hbx_update_ssn do
      can_update_ssn { true }
    end

    trait :hbx_read_only do
      name { 'hbx_read_only' }
      modify_family { true }
      modify_employer { false }
      revert_application { false }
      list_enrollments { true }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { true }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_outstanding_verification_sub_tab { true }
      can_access_pay_now { true }
    end

    trait :hbx_csr_supervisor do
      name { 'hbx_csr_supervisor' }
      modify_family { true }
      modify_employer { true }
      revert_application { true }
      list_enrollments { true }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { false }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_new_consumer_application_sub_tab { true }
      can_access_age_off_excluded {true}
      if EnrollRegistry[:enroll_app].setting(:state_abbreviation).item == 'ME'
        can_reinstate_enrollment {true}
        can_cancel_enrollment {true}
        can_terminate_enrollment {true}
        change_enrollment_end_date {true}
        can_drop_enrollment_members {true}
      end
    end

    trait :hbx_csr_tier2 do
      name { 'hbx_csr_tier2' }
      modify_family { true }
      modify_employer { true }
      revert_application { false }
      list_enrollments { false }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs { false }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_new_consumer_application_sub_tab { true }
      can_access_age_off_excluded {true}
      if EnrollRegistry[:enroll_app].setting(:state_abbreviation).item == 'ME'
        can_reinstate_enrollment {true}
        can_cancel_enrollment {true}
        can_terminate_enrollment {true}
        change_enrollment_end_date {true}
        can_drop_enrollment_members {true}
      end
    end

    trait :hbx_csr_tier1 do
      name { 'hbx_csr_tier1' }
      modify_family { true }
      modify_employer { false }
      revert_application { false }
      list_enrollments { false }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { false }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_new_consumer_application_sub_tab { true }
      can_access_age_off_excluded {true}
      can_access_pay_now { true }
      can_drop_enrollment_members {false}
    end

    trait :developer do
      name { 'developer' }
      modify_family { false }
      modify_employer { false }
      revert_application { false }
      list_enrollments { false }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { false }
      can_drop_enrollment_members {false}
    end

    trait :hbx_tier3 do
      name { 'hbx_tier3' }
      modify_family { true }
      modify_employer { false }
      revert_application { false }
      list_enrollments { true }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { true }
      can_create_benefit_application { true }
      can_manage_qles { true }
      view_the_configuration_tab { false }
      can_submit_time_travel_request { false }
      can_access_age_off_excluded {true}
      can_send_secure_message { true }
      can_edit_aptc {true}
      can_reinstate_enrollment {true}
      can_cancel_enrollment {true}
      can_terminate_enrollment {true}
      change_enrollment_end_date {true}
      can_drop_enrollment_members {true}
      can_call_hub {true}
    end

    trait :super_admin do
      name { 'super_admin' }
      can_complete_resident_application { true }
      can_add_sep { true }
      can_extend_open_enrollment { true }
      can_modify_plan_year { true }
      can_send_secure_message { true }
      can_create_benefit_application { true }
      can_manage_qles { true }
      can_force_publish { true }
      view_the_configuration_tab { true }
      can_submit_time_travel_request { false }
      can_access_age_off_excluded {true}
      can_edit_aptc {true}
      can_reinstate_enrollment {true}
      can_cancel_enrollment {true}
      can_terminate_enrollment {true}
      change_enrollment_end_date {true}
      can_drop_enrollment_members {true}
      can_call_hub {true}
    end
  end
end
