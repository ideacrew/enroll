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
    view_admin_tabs { true }
    can_lock_unlock { false }
    can_reset_password { false }

    trait :hbx_staff do
      can_complete_resident_application { true }
      can_add_sep { true }
    end

    trait :super_admin do
      can_edit_osse_eligibility {true}
      can_add_sep { true }
      can_edit_broker_agency_profile { true }
    end

    trait :hbx_csr_tier1 do
      can_edit_osse_eligibility {false}
      can_add_sep { true }
    end

    trait :hbx_read_only do
      can_edit_broker_agency_profile {false}
    end
  end
end