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

    trait :hbx_staff do
      can_complete_resident_application { true }
      can_add_sep { true }
      view_the_configuration_tab { false } 
      can_submit_time_travel_request { false }
      can_complete_resident_application true
      can_add_sep true
      name 'hbx_staff'
    end

    trait :hbx_update_ssn do
      can_update_ssn { true }
    end

    trait :hbx_read_only do
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
    end

    trait :hbx_csr_supervisor do
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
    end

    trait :hbx_csr_tier2 do
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
    end

    trait :hbx_csr_tier1 do
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
      modify_family true
      modify_employer false
      revert_application false
      list_enrollments true
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  true
      name 'hbx_read_only'
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
      name 'hbx_csr_supervisor'
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
      name 'hbx_csr_tier2'
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
      name 'hbx_csr_tier1'
    end

    trait :developer do
      modify_family { false }
      modify_employer { false }
      revert_application { false }
      list_enrollments { false }
      send_broker_agency_message { false }
      approve_broker { false }
      approve_ga { false }
      modify_admin_tabs { false }
      view_admin_tabs  { false }
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
      view_the_configuration_tab { false } 
      can_submit_time_travel_request { false }
    end

    trait :super_admin do
      name { 'super_admin' }
      can_complete_resident_application { true }
      can_add_sep { true }
      can_extend_open_enrollment { true }
      can_create_benefit_application { true }
      can_force_publish { true }
      view_the_configuration_tab { true } 
      can_submit_time_travel_request { false }
      modify_family false
      modify_employer false
      revert_application false
      list_enrollments false
      send_broker_agency_message false
      approve_broker false
      approve_ga false
      modify_admin_tabs false
      view_admin_tabs  false
      name 'developer'
    end
  end
end
