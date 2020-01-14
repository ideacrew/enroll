FactoryGirl.define do
  factory :permission do
    modify_family true
    modify_employer true
    revert_application true
    list_enrollments true
    send_broker_agency_message true
    approve_broker true
    approve_ga true
    modify_admin_tabs true
    view_admin_tabs  true
    can_lock_unlock false
    can_reset_password false

    trait :hbx_staff do
      can_complete_resident_application true
      can_add_sep true
      view_the_configuration_tab false 
      can_submit_time_travel_request false
    end

    trait :hbx_update_ssn do
      can_update_ssn true
    end

    trait :hbx_read_only do
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  true
      view_the_configuration_tab false 
      can_submit_time_travel_request false
    end

    trait :hbx_csr_supervisor do
      modify_family true
      modify_employer true
      revert_application true
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  false
      view_the_configuration_tab false 
      can_submit_time_travel_request false
    end

    trait :hbx_csr_tier2 do
      modify_family true
      modify_employer true
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs false
      view_the_configuration_tab false 
      can_submit_time_travel_request false
    end

    trait :hbx_csr_tier1 do
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  false
      view_the_configuration_tab false 
      can_submit_time_travel_request false
    end

    trait :developer do
      modify_family false
      modify_employer false
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  false
    end

    trait :hbx_tier3 do
      name 'hbx_tier3'
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  true
      can_create_benefit_application true
      can_update_enrollment_end_date true
      can_reinstate_enrollment true
      view_the_configuration_tab false
      can_submit_time_travel_request false
      can_view_username_and_email true
      can_lock_unlock true
      can_reset_password true
    end

    trait :super_admin do
      name 'super_admin'
      can_complete_resident_application true
      can_add_sep true
      can_extend_open_enrollment true
      can_modify_plan_year true
      can_create_benefit_application true
      can_force_publish true
      can_update_enrollment_end_date true
      can_reinstate_enrollment true
      view_the_configuration_tab true 
      can_submit_time_travel_request false
    end
  end
end